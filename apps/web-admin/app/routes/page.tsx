"use client";

import { useEffect, useState } from "react";
import Sidebar from "@/components/Sidebar";
import { apiFetch } from "@/lib/api";

type Stop = { id: number; name: string; sequence: number; latitude: number; longitude: number };
type Route = { id: number; name: string; origin: string; destination: string; stops: Stop[] };

export default function RoutesPage() {
  const [routes, setRoutes] = useState<Route[]>([]);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    apiFetch<Route[]>("/routes").then(setRoutes).catch((e) => setError(e.message));
  }, []);

  return (
    <div className="flex">
      <Sidebar />
      <main className="flex-1 px-10 py-8">
        <p className="font-display text-2xl font-semibold text-ink">Routes &amp; stops</p>
        <p className="text-slate text-sm mt-1">
          Each route&apos;s stops are what passengers search against for a live ETA.
        </p>

        {error && <p className="text-sm text-red-600 mt-4">{error}</p>}

        <div className="grid md:grid-cols-2 gap-4 mt-8">
          {routes.map((route) => (
            <div key={route.id} className="blueprint-frame bg-white/60 px-5 py-4">
              <p className="font-display text-lg font-semibold text-ink">{route.name}</p>
              <p className="text-sm text-slate">{route.origin} → {route.destination}</p>
              <ul className="mt-3 space-y-1">
                {route.stops.map((stop) => (
                  <li key={stop.id} className="text-sm text-ink flex justify-between">
                    <span>{stop.sequence}. {stop.name}</span>
                    <span className="telemetry text-slate/70 text-xs">
                      {stop.latitude.toFixed(4)}, {stop.longitude.toFixed(4)}
                    </span>
                  </li>
                ))}
              </ul>
            </div>
          ))}
          {routes.length === 0 && !error && (
            <p className="text-sm text-slate">No routes yet. Create one via the API (POST /routes).</p>
          )}
        </div>
      </main>
    </div>
  );
}
