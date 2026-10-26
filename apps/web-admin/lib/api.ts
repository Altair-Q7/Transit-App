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
};

export type LivePosition = {
  lat: number;
  lng: number;
  speed_kmh?: number | null;
  ts?: string | null;
};

export async function listActiveTrips(): Promise<Trip[]> {
  const response = await apiFetch<Trip[] | { trips?: Trip[] }>("/trips?status=active");
  if (Array.isArray(response)) return response;
  if (Array.isArray(response.trips)) return response.trips;
  throw new Error("The trip list response was not valid");
}

export function getTripLivePosition(tripId: number) {
  return apiFetch<LivePosition>(`/trips/${tripId}/live`).then((position) => {
    const lat = Number(position.lat);
    const lng = Number(position.lng);
    const speedRaw: number | string | null | undefined = position.speed_kmh;
    const speed = speedRaw == null || speedRaw === "" ? null : Number(speedRaw);
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
