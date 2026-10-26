"use client";

import { useState } from "react";
import Sidebar from "@/components/Sidebar";
import AuthGuard from "@/components/AuthGuard";
import { verifyIncident } from "@/lib/api";

export default function IncidentsPage() {
  const [incidentId, setIncidentId] = useState("");
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function handleVerify(event: React.FormEvent) {
    event.preventDefault();
    const id = Number(incidentId);
    if (!Number.isInteger(id) || id < 1) {
      setError("Enter a valid incident ID.");
      setMessage(null);
      return;
    }

    setLoading(true);
    setError(null);
    setMessage(null);
    try {
      const result = await verifyIncident(id);
      setMessage(`Incident #${result.id} verified. Passenger notification is enabled.`);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Could not verify incident");
    } finally {
      setLoading(false);
    }
  }

  return (
    <AuthGuard>
      <div className="flex">
        <Sidebar />
        <main className="flex-1 px-10 py-8">
          <p className="font-display text-2xl font-semibold text-ink">Incidents</p>
          <p className="text-slate text-sm mt-1">
            Verify crew-reported incidents before they are shared with passengers.
          </p>

          <section className="blueprint-frame bg-white/70 mt-8 max-w-xl px-5 py-5">
            <p className="font-display text-lg font-semibold text-ink">Verify an incident</p>
            <p className="text-sm text-slate mt-1">
              Enter the incident ID returned by the crew report endpoint.
            </p>
            <form onSubmit={handleVerify} className="mt-5 flex items-end gap-3">
              <label className="text-sm text-ink flex-1">
                Incident ID
                <input
                  type="number"
                  min="1"
                  required
                  value={incidentId}
                  onChange={(event) => setIncidentId(event.target.value)}
                  className="mt-1 w-full border border-line rounded px-3 py-2 bg-white outline-none focus:ring-2 focus:ring-rust"
                />
              </label>
              <button
                type="submit"
                disabled={loading}
                className="bg-rust text-white px-4 py-2 rounded hover:bg-rustDark disabled:opacity-60"
              >
                {loading ? "Verifying…" : "Verify"}
              </button>
            </form>
            {error && <p className="text-sm text-red-600 mt-4">{error}</p>}
            {message && <p className="text-sm text-good mt-4">{message}</p>}
          </section>

          <p className="text-xs text-slate/70 mt-5 max-w-xl">
            Verification uses the operator-scoped <span className="telemetry">POST /admin/incidents/&#123;id&#125;/verify</span> API.
          </p>
        </main>
      </div>
    </AuthGuard>
  );
}
