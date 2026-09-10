"use client";

import { useEffect, useState } from "react";
import Sidebar from "@/components/Sidebar";
import KpiTile from "@/components/KpiTile";
import { apiFetch } from "@/lib/api";

type Stats = {
  operator_value: { fleet_size: number; active_trips: number };
  passenger_value: { stop_searches_total: number };
  system_health: { availability_target: string; p95_target_ms: number };
};

export default function DashboardPage() {
  const [stats, setStats] = useState<Stats | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    apiFetch<Stats>("/admin/stats")
      .then(setStats)
      .catch((e) => setError(e.message));
  }, []);

  return (
    <div className="flex">
      <Sidebar />
      <main className="flex-1 px-10 py-8">
        <p className="font-display text-2xl font-semibold text-ink">Overview</p>
        <p className="text-slate text-sm mt-1">
          Live snapshot of your fleet — the same numbers behind the MVP success metrics.
        </p>

        {error && (
          <p className="mt-6 text-sm text-red-600">
            Couldn&apos;t load stats: {error}. Sign in again from the login page.
          </p>
        )}

        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mt-8">
          <KpiTile label="Buses in fleet" value={stats?.operator_value.fleet_size ?? "—"} />
          <KpiTile label="Active trips now" value={stats?.operator_value.active_trips ?? "—"} />
          <KpiTile label="Stop searches (platform)" value={stats?.passenger_value.stop_searches_total ?? "—"} />
          <KpiTile
            label="Availability target"
            value={stats?.system_health.availability_target ?? "—"}
            hint={stats ? `p95 < ${stats.system_health.p95_target_ms}ms` : undefined}
          />
        </div>
      </main>
    </div>
  );
}
