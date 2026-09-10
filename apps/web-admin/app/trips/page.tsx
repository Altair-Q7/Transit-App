"use client";

import { useEffect, useState } from "react";
import Sidebar from "@/components/Sidebar";
import { apiFetch } from "@/lib/api";

type Trip = { id: number; bus_id: number; route_id: number; status: string; started_at: string | null };

export default function TripsPage() {
  const [trips, setTrips] = useState<Trip[]>([]);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    // The MVP has no "list all trips" endpoint yet — this calls the
    // per-route live ETA/trip data once that's wired to a list route.
    // Left intentionally simple as a placeholder for the live map view.
    setError(null);
  }, []);

  return (
    <div className="flex">
      <Sidebar />
      <main className="flex-1 px-10 py-8">
        <p className="font-display text-2xl font-semibold text-ink">Live trips</p>
        <p className="text-slate text-sm mt-1">
          Trips currently broadcasting GPS pings over the WebSocket channel.
        </p>

        <div className="blueprint-frame bg-white/60 mt-8 h-96 flex items-center justify-center">
          <p className="text-sm text-slate/70">
            Map view goes here — subscribe to <span className="telemetry">/ws/trip/&#123;id&#125;</span> per
            active trip and plot the live lat/lng.
          </p>
        </div>

        {error && <p className="text-sm text-red-600 mt-4">{error}</p>}
        {trips.length > 0 && (
          <ul className="mt-6 space-y-2">
            {trips.map((t) => (
              <li key={t.id} className="text-sm text-ink">Trip #{t.id} — {t.status}</li>
            ))}
          </ul>
        )}
      </main>
    </div>
  );
}
