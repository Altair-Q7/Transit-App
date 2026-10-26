const API_URL = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8000/api/v1";
export const AUTH_REQUIRED_EVENT = "sarathy:auth-required";

export function getToken(): string | null {
  if (typeof window === "undefined") return null;
  return window.localStorage.getItem("sarathy_token");
}

export function hasToken(): boolean {
  return Boolean(getToken());
}

export function setToken(token: string) {
  window.localStorage.setItem("sarathy_token", token);
}

export function clearToken() {
  if (typeof window === "undefined") return;
  window.localStorage.removeItem("sarathy_token");
}

function notifyAuthRequired() {
  if (typeof window !== "undefined") {
    window.dispatchEvent(new Event(AUTH_REQUIRED_EVENT));
  }
}

function getErrorMessage(detail: unknown, status: number): string {
  if (typeof detail === "string") return detail;
  if (detail && typeof detail === "object" && "detail" in detail) {
    const message = (detail as { detail?: unknown }).detail;
    if (typeof message === "string") return message;
  }
  return `Request failed: ${status}`;
}

export async function apiFetch<T>(path: string, options: RequestInit = {}): Promise<T> {
  const token = getToken();
  const res = await fetch(`${API_URL}${path}`, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...options.headers,
    },
  });

  if (!res.ok) {
    const detail = await res.json().catch(() => ({}));
    if (res.status === 401) {
      clearToken();
      notifyAuthRequired();
    }
    const error = new Error(getErrorMessage(detail, res.status));
    error.name = `ApiError${res.status}`;
    throw error;
  }

  if (res.status === 204) return undefined as T;
  return res.json() as Promise<T>;
}

export async function loginOperator(email: string, password: string) {
  const body = new URLSearchParams({ username: email, password });
  const res = await fetch(`${API_URL}/auth/operator/login`, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body,
  });
  if (!res.ok) {
    const detail = await res.json().catch(() => ({}));
    throw new Error(getErrorMessage(detail, res.status));
  }
  const data = await res.json();
  if (!data.access_token) throw new Error("Login response did not include an access token");
  setToken(data.access_token);
  return data;
}

export type Trip = {
  id: number;
  bus_id: number;
  route_id: number;
  status: string;
  started_at: string | null;
  ended_at?: string | null;
  crew_id?: number | null;
  created_at?: string;
};

export type LivePosition = {
  lat: number;
  lng: number;
  speed_kmh?: number | null;
  ts?: string | null;
};

export async function listActiveTrips(): Promise<Trip[]> {
  const response = await apiFetch<Trip[] | { trips?: Trip[] }>("/operator/trips");
  const trips = Array.isArray(response)
    ? response
    : Array.isArray(response.trips)
      ? response.trips
      : (() => { throw new Error("The trip list response was not valid"); })();
  return trips.filter((trip) => trip.status === "active");
}

export function getTripLivePosition(tripId: number) {
  return apiFetch<LivePosition>(`/trips/${tripId}/live`).then((position) => {
    const lat = Number(position.lat);
    const lng = Number(position.lng);
    const speedRaw = position.speed_kmh;
    const speed = speedRaw == null ? null : Number(speedRaw);
    if (!Number.isFinite(lat) || !Number.isFinite(lng) || (speed !== null && !Number.isFinite(speed))) {
      throw new Error("The live position response was not valid");
    }
    return { ...position, lat, lng, speed_kmh: speed };
  });
}

export function verifyIncident(incidentId: number) {
  return apiFetch<{ id: number; status: string; notify_passengers: boolean }>(
    `/admin/incidents/${incidentId}/verify`,
    { method: "POST" },
  );
}

export type Incident = {
  id: number;
  trip_id: number;
  type: string;
  note: string;
  reported_at: string;
  admin_verified: boolean;
  verified_at?: string | null;
};

export async function listIncidents(): Promise<Incident[]> {
  const response = await apiFetch<Incident[] | { incidents?: Incident[] }>("/operator/incidents");
  const incidents = Array.isArray(response)
    ? response
    : Array.isArray(response.incidents)
      ? response.incidents
      : (() => { throw new Error("The incident list response was not valid"); })();
  return incidents;
}

export type CrewRole = "driver" | "conductor";

export type Crew = {
  id: number;
  name: string;
  phone: string;
  role: CrewRole;
};

export type CrewInput = {
  name: string;
  phone: string;
  password: string;
  role: CrewRole;
};

export async function listCrew(): Promise<Crew[]> {
  const response = await apiFetch<Crew[] | { crew?: Crew[] }>("/operator/crew");
  const members = Array.isArray(response)
    ? response
    : Array.isArray(response.crew)
      ? response.crew
      : (() => { throw new Error("The crew list response was not valid"); })();
  return members;
}

export async function createCrew(input: CrewInput): Promise<Crew> {
  return apiFetch<Crew>("/operator/crew", {
    method: "POST",
    body: JSON.stringify(input),
  });
}
