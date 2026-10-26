"use client";

import { useCallback, useEffect, useState } from "react";
import Sidebar from "@/components/Sidebar";
import AuthGuard from "@/components/AuthGuard";
import { listIncidents, verifyIncident, type Incident } from "@/lib/api";

function formatDate(value: string | null) {
  if (!value) return "—";
  return new Date(value).toLocaleString();
}

export default function IncidentsPage() {
  const [incidents, setIncidents] = useState<Incident[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [verifyingId, setVerifyingId] = useState<number | null>(null);

  const loadIncidents = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      setIncidents(await listIncidents());
    } catch (err) {
      setError(err instanceof Error ? err.message : "Could not load incidents");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void loadIncidents();
  }, [loadIncidents]);

  const handleVerify = async (id: number) => {
    setVerifyingId(id);
    setError(null);
    try {
      await verifyIncident(id);
      await loadIncidents();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Could not verify incident");
    } finally {
      setVerifyingId(null);
    }
  };

  return (
    <AuthGuard>
      <div className="flex">
        <Sidebar />
        <main className="flex-1 px-10 py-8">
          <p className="font-display text-2xl font-semibold text-ink">Incidents</p>
          <p className="text-slate text-sm mt-1">
            Review crew-reported incidents and verify them before passengers are notified.
          </p>

          {error && (
            <div className="bg-red-50 mt-8 px-5 py-4 text-sm text-red-700 border border-red-100 rounded">
              <p>{error}</p>
              <button type="button" onClick={() => void loadIncidents()} className="mt-2 underline text-sm">
                Try again
              </button>
            </div>
          )}

          {loading && !error && (
            <div className="bg-white/60 mt-8 px-5 py-8 text-sm text-slate border border-line rounded">
              Loading incidents…
            </div>
          )}

          {!loading && !error && incidents.length === 0 && (
            <div className="bg-white/60 mt-8 px-5 py-8 border border-line rounded">
              <p className="font-display text-lg font-semibold text-ink">No incidents reported</p>
              <p className="text-sm text-slate mt-1">
                Crew-reported incidents will appear here for verification.
              </p>
            </div>
          )}

          {!loading && !error && incidents.length > 0 && (
            <div className="blueprint-frame bg-white/70 mt-8 overflow-x-auto sm:overflow-visible">
              <table className="w-full text-sm text-left border-collapse">
                <thead>
                  <tr className="border-b border-line text-slate">
                    <th className="px-4 py-3">ID</th>
                    <th className="px-4 py-3">Trip</th>
                    <th className="px-4 py-3">Type</th>
                    <th className="px-4 py-3">Note</th>
                    <th className="px-4 py-3">Reported</th>
                    <th className="px-4 py-3">Status</th>
                    <th className="px-4 py-3">Action</th>
                  </tr>
                </thead>
                <tbody>
                  {incidents.map((incident) => (
                    <tr key={incident.id} className="border-b border-line bg-white/60">
                      <td className="px-4 py-3 telemetry">{incident.id}</td>
                      <td className="px-4 py-3 telemetry">#{incident.trip_id}</td>
                      <td className="px-4 py-3 text-ink">{incident.type}</td>
                      <td className="px-4 py-3">{incident.note}</td>
                      <td className="px-4 py-3 text-slate/70 telemetry">
                        {formatDate(incident.reported_at)}
                      </td>
                      <td className="px-4 py-3">
                        <span
                          className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold uppercase tracking-wide ${
                            incident.admin_verified ? "bg-good/10 text-good" : "bg-amber-100 text-amber-700"
                          }`}
                        >
                          {incident.admin_verified ? "Verified" : "Unverified"}
                        </span>
                      </td>
                      <td className="px-4 py-3">
                        {!incident.admin_verified && (
                          <button
                            disabled={verifyingId === incident.id}
                            onClick={() => void handleVerify(incident.id)}
                            className="bg-rust text-white px-3 py-1.5 rounded text-xs hover:bg-rustDark disabled:opacity-60"
                          >
                            {verifyingId === incident.id ? "Verifying…" : "Verify"}
                          </button>
                        )}
                        {incident.admin_verified && incident.verified_at && (
                          <p className="text-xs text-slate/70 telemetry mt-1">
                            Verified {formatDate(incident.verified_at)}
                          </p>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}

          <p className="text-xs text-slate/70 mt-5 max-w-xl">
            Verification uses the operator-scoped <span className="telemetry">POST /admin/incidents/&#123;id&#125;/verify</span> API.
          </p>
        </main>
      </div>
    </AuthGuard>
  );
}
