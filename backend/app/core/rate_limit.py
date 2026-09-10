"""
Two related but distinct protections, both backed by Redis so they work
correctly even when you scale the backend to multiple replicas:

1. General rate limiting — a sliding-window counter per (client IP, route).
2. Login lockout — a stricter, per-identifier (email/phone) counter that
   locks an account out after N failed attempts, independent of IP, so an
   attacker can't just rotate IPs to keep guessing one account's password.
"""
import time

from fastapi import HTTPException, Request, status

from app.services.redis_client import get_redis


def _parse_rate(rate: str) -> tuple[int, int]:
    """'10/minute' -> (10, 60); '60/minute' -> (60, 60)."""
    count_str, _, unit = rate.partition("/")
    count = int(count_str)
    seconds = {"second": 1, "minute": 60, "hour": 3600}.get(unit, 60)
    return count, seconds


async def enforce_rate_limit(request: Request, rate: str, bucket: str) -> None:
    """
    Call from a route/dependency to enforce `rate` (e.g. "10/minute") for
    the given logical `bucket` name, keyed by client IP.
    """
    limit, window = _parse_rate(rate)
    client_ip = request.client.host if request.client else "unknown"
    key = f"ratelimit:{bucket}:{client_ip}:{int(time.time()) // window}"

    r = get_redis()
    count = await r.incr(key)
    if count == 1:
        await r.expire(key, window)

    if count > limit:
        raise HTTPException(
            status.HTTP_429_TOO_MANY_REQUESTS,
            f"Too many requests — limit is {rate}. Try again shortly.",
        )


async def check_login_lockout(identifier: str, max_attempts: int, lockout_seconds: int) -> None:
    """Raise 429 if this identifier (email/phone) is currently locked out."""
    r = get_redis()
    attempts = await r.get(f"login_attempts:{identifier}")
    if attempts and int(attempts) >= max_attempts:
        raise HTTPException(
            status.HTTP_429_TOO_MANY_REQUESTS,
            f"Too many failed login attempts. Try again in a few minutes.",
        )


async def record_failed_login(identifier: str, lockout_seconds: int) -> None:
    r = get_redis()
    key = f"login_attempts:{identifier}"
    count = await r.incr(key)
    if count == 1:
        await r.expire(key, lockout_seconds)


async def clear_failed_logins(identifier: str) -> None:
    r = get_redis()
    await r.delete(f"login_attempts:{identifier}")
