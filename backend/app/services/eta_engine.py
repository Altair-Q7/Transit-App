"""
The ETA Accuracy Evolution Matrix, MVP phase:
  Inputs:  GPS + Route Distance + Historical Speed
  Output:  Baseline Confidence

This module is intentionally isolated behind get_eta() so Version 2
(traffic APIs + time-of-day models) and Version 3 (ML + weather +
delays) can replace the internals without touching callers.
"""
import math

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
