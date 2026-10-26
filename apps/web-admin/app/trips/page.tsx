"use client";

import { useCallback, useEffect, useState } from "react";
import Sidebar from "@/components/Sidebar";
import AuthGuard from "@/components/AuthGuard";
import { getTripLivePosition, listActiveTrips, type LivePosition, type Trip } from "@/lib/api";

type TripWithPosition = Trip & {
  position: LivePosition | null;
  positionError?: string;
};

function formatDate(value: string | null) {
  if (!value) return "Not started";
  return new Date(value).toLocaleString();
}

function formatPosition(position: LivePosition | null) {
  if (!position) return "No live coordinate yet";
  return `${position.lat.toFixed(5)}, ${position.lng.toFixed(5)}`;
}

export default function TripsPage() {
  const [trips, setTrips] = useState<TripWithPosition[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const loadTrips = useCallback(async (showRefreshState = false) => {
    if (showRefreshState) setRefreshing(true);
    else setLoading(true);
    setError(null);

    try {
      const activeTrips = await listActiveTrips();
      const withPositions = await Promise.all(
        activeTrips
          .filter((trip) => trip.status.toLowerCase() === "active")
          .map(async (trip): Promise<TripWithPosition> => {
            try {
              return { ...trip, position: await getTripLivePosition(trip.id) };
            } catch (err) {
              return {
                ...trip,
                position: null,
                positionError: err instanceof Error ? err.message : "Live position unavailable",
              };
            }
          }),
      );
      setTrips(withPositions);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Could not load active trips");
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, []);

  useEffect(() => {
    void loadTrips();
    const interval = window.setInterval(() => void loadTrips(true), 15000);
    return () => window.clearInterval(interval);
  }, [loadTrips]);

  return (
    <AuthGuard>
      <div className="flex">
        <Sidebar />
        <main className="flex-1 px-10 py-8">
        <div className="flex items-start justify-between gap-4">
          <div>
            <p className="font-display text-2xl font-semibold text-ink">Live trips</p>
            <p className="text-slate text-sm mt-1">
              Active trips and their latest coordinates from the operator API.
            </p>
          </div>
          <button
            type="button"
            onClick={() => void loadTrips(true)}
            disabled={loading || refreshing}
            className="border border-line bg-white/70 px-4 py-2 rounded text-sm text-ink hover:border-rust disabled:opacity-50"
          >
            {refreshing ? "Refreshing…" : "Refresh"}
          </button>
        </div>

        {error && (
          <div className="blueprint-frame bg-red-50 mt-8 px-5 py-4 text-sm text-red-700">
            <p>Couldn&apos;t load active trips: {error}</p>
            <button type="button" onClick={() => void loadTrips()} className="mt-2 underline">
              Try again
            </button>
          </div>
        )}

        {loading && !error && (
          <div className="blueprint-frame bg-white/60 mt-8 px-5 py-8 text-sm text-slate">
            Loading active trips…
          </div>
        )}

        {!loading && !error && trips.length === 0 && (
          <div className="blueprint-frame bg-white/60 mt-8 px-5 py-8">
            <p className="font-display text-lg font-semibold text-ink">No active trips</p>
            <p className="text-sm text-slate mt-1">
              Active trips will appear here when a crew member starts a route.
            </p>
          </div>
        )}

        {trips.length > 0 && (
          <div className="grid gap-4 md:grid-cols-2 mt-8">
            {trips.map((trip) => (
              <article key={trip.id} className="blueprint-frame bg-white/70 px-5 py-4">
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <p className="font-display text-lg font-semibold text-ink">Trip #{trip.id}</p>
                    <p className="text-sm text-slate">Bus #{trip.bus_id} · Route #{trip.route_id}</p>
                  </div>
                  <span className="rounded-full bg-good/10 px-2.5 py-1 text-xs font-semibold uppercase tracking-wide text-good">
                    {trip.status}
                  </span>
                </div>

                <dl className="mt-5 grid grid-cols-2 gap-x-4 gap-y-3 text-sm">
                  <div>
                    <dt className="text-slate">Latest coordinate</dt>
                    <dd className="telemetry text-ink mt-0.5">{formatPosition(trip.position)}</dd>
                  </div>
                  <div>
                    <dt className="text-slate">Speed</dt>
                    <dd className="telemetry text-ink mt-0.5">
                      {trip.position?.speed_kmh == null ? "—" : `${trip.position.speed_kmh.toFixed(1)} km/h`}
                    </dd>
                  </div>
                  <div className="col-span-2">
                    <dt className="text-slate">Started</dt>
                    <dd className="text-ink mt-0.5">{formatDate(trip.started_at)}</dd>
                  </div>
                </dl>

                {trip.position && trip.position.ts && (
                  <p className="text-xs text-slate/70 mt-4">Last GPS update: {formatDate(trip.position.ts)}</p>
                )}
                {!trip.position && (
                  <p className="text-xs text-amber-700 mt-4">
                    {trip.positionError ?? "Waiting for the first GPS update."}
                  </p>
                )}
              </article>
            ))}
          </div>
        )}
        </main>
      </div>
    </AuthGuard>
  );
}
