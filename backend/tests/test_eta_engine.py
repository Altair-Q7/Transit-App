from app.services.eta_engine import estimate_eta, estimate_route_eta


def test_missing_speed_has_low_confidence():
    estimate = estimate_eta(0, 0, 0, 1, current_speed_kmh=None)

    assert estimate["confidence"] == "low"


def test_route_eta_uses_remaining_route_and_marks_passed_stops():
    stops = [
        (1, 0.0, 0.0),
        (2, 0.0, 1.0),
        (3, 1.0, 1.0),
    ]

    en_route = estimate_route_eta(0.0, 0.1, stops, target_sequence=3, current_speed_kmh=20)
    departed = estimate_route_eta(1.0, 1.0, stops, target_sequence=2, current_speed_kmh=20)

    assert en_route["status"] == "en_route"
    assert en_route["distance_km"] > 100
    assert departed["status"] == "departed"
    assert departed["eta_minutes"] == 0.0
