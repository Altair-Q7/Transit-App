from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr


# ---------- Auth ----------

class OperatorSignup(BaseModel):
    name: str
    email: EmailStr
    password: str


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    role: str


class CrewLogin(BaseModel):
    phone: str
    password: str


# ---------- Fleet ----------

class BusCreate(BaseModel):
    registration_number: str
    capacity: int = 45


class BusOut(BaseModel):
    id: int
    registration_number: str
    capacity: int
    active: bool

    model_config = ConfigDict(from_attributes=True)


class StopCreate(BaseModel):
    name: str
    sequence: int
    latitude: float
    longitude: float


class StopOut(StopCreate):
    id: int

    model_config = ConfigDict(from_attributes=True)


class RouteCreate(BaseModel):
    name: str
    origin: str
    destination: str
    stops: list[StopCreate] = []


class RouteOut(BaseModel):
    id: int
    name: str
    origin: str
    destination: str
    stops: list[StopOut] = []

    model_config = ConfigDict(from_attributes=True)


# ---------- Trips / GPS / ETA ----------

class TripStart(BaseModel):
    bus_id: int
    route_id: int
    crew_id: int | None = None


class GpsPing(BaseModel):
    trip_id: int
    latitude: float
    longitude: float
    speed_kmh: float | None = None


class TripOut(BaseModel):
    id: int
    bus_id: int
    route_id: int
    status: str
    started_at: datetime | None
    ended_at: datetime | None

    model_config = ConfigDict(from_attributes=True)


class EtaResponse(BaseModel):
    trip_id: int
    stop_id: int
    eta_minutes: float
    confidence: str  # "low" | "medium" | "high"
    distance_km: float
    status: str = "on_time"  # on_time | delayed


class IncidentReport(BaseModel):
    trip_id: int
    type: str  # breakdown | traffic | emergency
    note: str | None = None
