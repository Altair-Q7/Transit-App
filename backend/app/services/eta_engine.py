"""
The ETA Accuracy Evolution Matrix, MVP phase:
  Inputs:  GPS + Route Distance + Historical Speed
  Output:  Baseline Confidence

This module is intentionally isolated behind get_eta() so Version 2
(traffic APIs + time-of-day models) and Version 3 (ML + weather +
delays) can replace the internals without touching callers.
"""
import math
from collections.abc import Sequence

from app.core.config import settings

DEFAULT_AVG_SPEED_KMH = 28.0  # fallback historical average for a city bus
HIGH_CONFIDENCE_NEAR_STOP_KM = 1.0


def haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    r = 6371.0
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
    return 2 * r * math.asin(math.sqrt(a))


def _effective_speed(
    current_speed_kmh: float | None,
    historical_avg_speed_kmh: float,
) -> float:
    # Blend live speed with historical average; live speed dominates
    # once the bus is clearly moving (avoids div-by-zero at red lights).
    if current_speed_kmh and current_speed_kmh > 3:
        return 0.7 * current_speed_kmh + 0.3 * historical_avg_speed_kmh
    return historical_avg_speed_kmh


def _confidence(
    current_speed_kmh: float | None,
    historical_avg_speed_kmh: float,
    *,
    progress_known: bool = False,
    nearest_stop_km: float | None = None,
) -> str:
    """Derive confidence from live speed variance and route progress.

    Rules:
      * no live speed -> "low";
      * live speed whose relative variance versus the historical average
        ``|current - historical| / historical`` exceeds
        ``settings.eta_confidence_speed_variance`` -> "low";
      * otherwise "medium";
      * upgraded to "high" only when the speed is present, its variance is
        within the threshold, persisted route progress is known, and the
        nearest stop is within 1.0 km of the bus.
    """
    if current_speed_kmh is None:
        return "low"
    if historical_avg_speed_kmh <= 0:
        return "low"
    variance = abs(current_speed_kmh - historical_avg_speed_kmh) / historical_avg_speed_kmh
    if variance > settings.eta_confidence_speed_variance:
        return "low"
    if (
        progress_known
        and nearest_stop_km is not None
        and nearest_stop_km <= HIGH_CONFIDENCE_NEAR_STOP_KM
    ):
        return "high"
    return "medium"


def estimate_eta(
    bus_lat: float,
    bus_lng: float,
    stop_lat: float,
    stop_lng: float,
    current_speed_kmh: float | None,
    historical_avg_speed_kmh: float = DEFAULT_AVG_SPEED_KMH,
) -> dict:
    distance_km = haversine_km(bus_lat, bus_lng, stop_lat, stop_lng)
    effective_speed = _effective_speed(current_speed_kmh, historical_avg_speed_kmh)
    eta_minutes = (distance_km / max(effective_speed, 1.0)) * 60
    confidence = _confidence(current_speed_kmh, historical_avg_speed_kmh)

    return {
        "distance_km": round(distance_km, 2),
        "eta_minutes": round(eta_minutes, 1),
        "confidence": confidence,
    }


def estimate_route_eta(
    bus_lat: float,
    bus_lng: float,
    stops: Sequence[tuple[int, float, float]],
    target_sequence: int,
    current_speed_kmh: float | None,
    historical_avg_speed_kmh: float = DEFAULT_AVG_SPEED_KMH,
    *,
    last_stop_sequence: int | None = None,
    dwell_seconds: int = 0,
) -> dict:
    """Estimate along the ordered route and mark stops the bus has passed.

    ``stops`` contains ``(sequence, latitude, longitude)`` tuples. The nearest
    stop is used as a lightweight progress marker when the trip has no
    persisted ``last_stop_sequence`` yet.

    Departed rules:
      * the target is off the route -> "departed";
      * persisted progress is known -> "departed" only when
        ``target_sequence <= last_stop_sequence``;
      * no persisted progress -> "departed" only when the nearest stop is
        strictly later than the target; if the nearest stop *is* the target
        the trip stays "en_route" with the remaining distance to that stop.

    ``dwell_seconds`` is added per intermediate stop (stops strictly between
    the nearest stop and the target) to the travel time.

    Confidence follows :func:`_confidence`: no speed -> "low"; large relative
    speed variance versus the historical average -> "low"; otherwise
    "medium"; "high" requires variance within the threshold, persisted route
    progress, and a nearest stop within 1.0 km.
    """
    if not stops:
        estimate = estimate_eta(
            bus_lat,
            bus_lng,
            bus_lat,
            bus_lng,
            current_speed_kmh,
            historical_avg_speed_kmh,
        )
        estimate["status"] = "en_route"
        return estimate

    ordered_stops = sorted(stops, key=lambda stop: stop[0])
    stop_distances = [
        haversine_km(bus_lat, bus_lng, stop[1], stop[2])
        for stop in ordered_stops
    ]
    nearest_index = min(range(len(ordered_stops)), key=stop_distances.__getitem__)
    nearest_stop_km = stop_distances[nearest_index]
    target_index = next(
        (index for index, stop in enumerate(ordered_stops) if stop[0] == target_sequence),
        None,
    )

    confidence = _confidence(
        current_speed_kmh,
        historical_avg_speed_kmh,
        progress_known=last_stop_sequence is not None,
        nearest_stop_km=nearest_stop_km,
    )

    if target_index is None:
        return {
            "distance_km": 0.0,
            "eta_minutes": 0.0,
            "confidence": confidence,
            "status": "departed",
        }

    if last_stop_sequence is not None:
        departed = target_sequence <= last_stop_sequence
    else:
        departed = target_index < nearest_index

    if departed:
        return {
            "distance_km": 0.0,
            "eta_minutes": 0.0,
            "confidence": confidence,
            "status": "departed",
        }

    if nearest_index >= target_index:
        # The bus is at/near the target (or physically ahead of it while
        # persisted progress says it has not reached it yet): the remaining
        # distance is the direct distance to the target stop.
        distance_km = haversine_km(
            bus_lat,
            bus_lng,
            ordered_stops[target_index][1],
            ordered_stops[target_index][2],
        )
    else:
        next_stop = ordered_stops[nearest_index + 1]
        distance_km = haversine_km(
            bus_lat,
            bus_lng,
            next_stop[1],
            next_stop[2],
        )
        for index in range(nearest_index + 1, target_index):
            current_stop = ordered_stops[index]
            following_stop = ordered_stops[index + 1]
            distance_km += haversine_km(
                current_stop[1],
                current_stop[2],
                following_stop[1],
                following_stop[2],
            )

    effective_speed = _effective_speed(current_speed_kmh, historical_avg_speed_kmh)
    travel_minutes = (distance_km / max(effective_speed, 1.0)) * 60
    intermediate_count = max(target_index - nearest_index - 1, 0)
    dwell_minutes = intermediate_count * max(dwell_seconds, 0) / 60
    eta_minutes = travel_minutes + dwell_minutes

    return {
        "distance_km": round(distance_km, 2),
        "eta_minutes": round(eta_minutes, 1),
        "confidence": confidence,
        "status": "en_route",
    }
