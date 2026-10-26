import pytest
from fastapi import HTTPException

from app.api import deps
from app.models.operator import Crew


class FakeCrew:
    operator_id = 7


class FakeDb:
    def get(self, model, object_id):
        if model is Crew and object_id == 3:
            return FakeCrew()
        return None


def test_crew_claims_require_existing_matching_operator(monkeypatch):
    monkeypatch.setattr(deps, "decode_access_token", lambda token: {
        "sub": "3",
        "role": "crew",
        "operator_id": "7",
    })

    claims = deps.get_current_crew_claims("token", FakeDb())

    assert claims["sub"] == "3"


def test_crew_claims_reject_unknown_crew(monkeypatch):
    monkeypatch.setattr(deps, "decode_access_token", lambda token: {
        "sub": "99",
        "role": "crew",
        "operator_id": "7",
    })

    with pytest.raises(HTTPException) as error:
        deps.get_current_crew_claims("token", FakeDb())

    assert error.value.status_code == 401
