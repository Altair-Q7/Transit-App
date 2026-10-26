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


def test_bus_closer_to_target_than_previous_stop_without_progress_is_en_route():
    stops = [
        (1, 0.0, 0.0),
        (2, 0.0, 0.02),
        (3, 0.0, 0.04),
    ]

    estimate = estimate_route_eta(0.0, 0.015, stops, target_sequence=2, current_speed_kmh=20)

    assert estimate["status"] == "en_route"
    assert 0 < estimate["distance_km"] < 1.0


def test_persisted_progress_at_target_marks_it_departed():
    stops = [
        (1, 0.0, 0.0),
        (2, 0.0, 0.02),
        (3, 0.0, 0.04),
    ]

    estimate = estimate_route_eta(
        0.0,
        0.015,
        stops,
        target_sequence=2,
        current_speed_kmh=20,
        last_stop_sequence=2,
    )

    assert estimate["status"] == "departed"


def test_persisted_progress_behind_target_stays_en_route_near_target():
    stops = [
        (1, 0.0, 0.0),
        (2, 0.0, 0.02),
        (3, 0.0, 0.04),
    ]

    estimate = estimate_route_eta(
        0.0,
        0.019,
        stops,
        target_sequence=2,
        current_speed_kmh=20,
        last_stop_sequence=1,
    )

    assert estimate["status"] == "en_route"
    assert estimate["distance_km"] > 0


def test_dwell_adds_time_only_for_intermediate_stops():
    stops = [
        (1, 0.0, 0.0),
        (2, 0.0, 0.01),
        (3, 0.0, 0.02),
        (4, 0.0, 0.03),
    ]

    without_dwell = estimate_route_eta(0.0, 0.0005, stops, target_sequence=4, current_speed_kmh=20)
    with_dwell = estimate_route_eta(
        0.0,
        0.0005,
        stops,
        target_sequence=4,
        current_speed_kmh=20,
        dwell_seconds=60,
    )
    target_is_nearest_without = estimate_route_eta(
        0.0,
        0.011,
        stops,
        target_sequence=2,
        current_speed_kmh=20,
    )
    target_is_nearest_with = estimate_route_eta(
        0.0,
        0.011,
        stops,
        target_sequence=2,
        current_speed_kmh=20,
        dwell_seconds=60,
    )

    # Two intermediate stops (2 and 3) at 60s each => +2 minutes.
    assert with_dwell["eta_minutes"] >= without_dwell["eta_minutes"] + 1.9
    assert target_is_nearest_with["eta_minutes"] == target_is_nearest_without["eta_minutes"]


def test_confidence_uses_speed_variance_progress_and_stop_distance():
    stops = [
        (1, 0.0, 0.0),
        (2, 0.0, 0.02),
    ]

    no_speed = estimate_route_eta(
        0.0, 0.001, stops, target_sequence=2, current_speed_kmh=None, last_stop_sequence=1
    )
    big_variance = estimate_route_eta(
        0.0, 0.001, stops, target_sequence=2, current_speed_kmh=5, last_stop_sequence=1
    )
    no_progress = estimate_route_eta(0.0, 0.001, stops, target_sequence=2, current_speed_kmh=30)
    with_progress_near_stop = estimate_route_eta(
        0.0, 0.001, stops, target_sequence=2, current_speed_kmh=30, last_stop_sequence=1
    )

    assert no_speed["confidence"] == "low"
    assert big_variance["confidence"] == "low"
    assert no_progress["confidence"] == "medium"
    assert with_progress_near_stop["confidence"] == "high"


def test_bus_beyond_target_without_progress_is_still_departed():
    stops = [
        (1, 0.0, 0.0),
        (2, 0.0, 0.02),
        (3, 0.0, 0.04),
    ]

    estimate = estimate_route_eta(0.0, 0.045, stops, target_sequence=2, current_speed_kmh=20)

    assert estimate["status"] == "departed"
    assert estimate["eta_minutes"] == 0.0
