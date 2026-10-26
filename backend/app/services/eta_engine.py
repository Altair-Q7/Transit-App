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

DEFAULT_AVG_SPEED_KMH = 28.0  # fallback historical average for a city bus


def haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    r = 6371.0
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
    return 2 * r * math.asin(math.sqrt(a))


def estimate_eta(
    bus_lat: float,
    bus_lng: float,
    stop_lat: float,
    stop_lng: float,
    current_speed_kmh: float | None,
    historical_avg_speed_kmh: float = DEFAULT_AVG_SPEED_KMH,
) -> dict:
    distance_km = haversine_km(bus_lat, bus_lng, stop_lat, stop_lng)

    # Blend live speed with historical average; live speed dominates
    # once the bus is clearly moving (avoids div-by-zero at red lights).
    if current_speed_kmh and current_speed_kmh > 3:
        effective_speed = 0.7 * current_speed_kmh + 0.3 * historical_avg_speed_kmh
        confidence = "high"
    elif current_speed_kmh is not None:
        effective_speed = historical_avg_speed_kmh
        confidence = "medium"
    else:
        effective_speed = historical_avg_speed_kmh
        confidence = "low"

    eta_minutes = (distance_km / max(effective_speed, 1.0)) * 60

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
) -> dict:
    """Estimate along the ordered route and mark stops the bus has passed.

    ``stops`` contains ``(sequence, latitude, longitude)`` tuples. The nearest
    stop is used as a lightweight progress marker until persistent route
    progress is available on trips.
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
    nearest_index = min(
        range(len(ordered_stops)),
        key=lambda index: haversine_km(
            bus_lat,
            bus_lng,
            ordered_stops[index][1],
            ordered_stops[index][2],
        ),
    )
    target_index = next(
        (index for index, stop in enumerate(ordered_stops) if stop[0] == target_sequence),
        None,
    )

    if target_index is None or target_index <= nearest_index:
        return {
            "distance_km": 0.0,
            "eta_minutes": 0.0,
            "confidence": "low" if current_speed_kmh is None else "medium",
            "status": "departed",
        }

    next_stop = ordered_stops[nearest_index + 1]
    distance_km = haversine_km(bus_lat, bus_lng, next_stop[1], next_stop[2])
    for index in range(nearest_index + 1, target_index):
        current_stop = ordered_stops[index]
        following_stop = ordered_stops[index + 1]
        distance_km += haversine_km(
            current_stop[1],
            current_stop[2],
            following_stop[1],
            following_stop[2],
        )

    estimate = estimate_eta(
        bus_lat,
        bus_lng,
        bus_lat,
        bus_lng,
        current_speed_kmh,
        historical_avg_speed_kmh,
    )
    effective_speed = (
        0.7 * current_speed_kmh + 0.3 * historical_avg_speed_kmh
        if current_speed_kmh and current_speed_kmh > 3
        else historical_avg_speed_kmh
    )
    estimate["distance_km"] = round(distance_km, 2)
    estimate["eta_minutes"] = round((distance_km / max(effective_speed, 1.0)) * 60, 1)
    estimate["status"] = "en_route"
    return estimate
