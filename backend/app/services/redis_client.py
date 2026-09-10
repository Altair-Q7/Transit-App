"""
Layer 3: The Data — Redis side.
Used for two things per the architecture slide:
  1. High-frequency live ETA / location caching (so MariaDB isn't hit
     on every 5s GPS ping).
  2. Pub/sub fan-out so any FastAPI worker can broadcast a trip update
     to WebSocket clients connected to a *different* worker.
"""
import json
from functools import lru_cache

import redis.asyncio as aioredis

from app.core.config import settings

LIVE_TRIP_KEY = "trip:live:{trip_id}"       # hash: lat, lng, speed, ts
TRIP_CHANNEL = "trip:updates:{trip_id}"     # pub/sub channel


@lru_cache
def get_redis() -> aioredis.Redis:
    return aioredis.from_url(settings.redis_url, decode_responses=True)


async def set_live_position(trip_id: int, lat: float, lng: float, speed_kmh: float | None, ts: str) -> None:
    r = get_redis()
    key = LIVE_TRIP_KEY.format(trip_id=trip_id)
    await r.hset(key, mapping={
        "lat": lat, "lng": lng, "speed_kmh": speed_kmh or 0, "ts": ts,
    })
    await r.expire(key, 60 * 30)  # auto-expire stale trips after 30 min


async def get_live_position(trip_id: int) -> dict | None:
    r = get_redis()
    data = await r.hgetall(LIVE_TRIP_KEY.format(trip_id=trip_id))
    return data or None


async def publish_trip_update(trip_id: int, payload: dict) -> None:
    r = get_redis()
    await r.publish(TRIP_CHANNEL.format(trip_id=trip_id), json.dumps(payload))
