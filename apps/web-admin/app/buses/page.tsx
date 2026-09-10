"use client";

import { useEffect, useState } from "react";
import Sidebar from "@/components/Sidebar";
import { apiFetch } from "@/lib/api";

type Bus = { id: number; registration_number: string; capacity: number; active: boolean };

export default function BusesPage() {
  const [buses, setBuses] = useState<Bus[]>([]);
  const [reg, setReg] = useState("");
  const [capacity, setCapacity] = useState(45);
  const [error, setError] = useState<string | null>(null);

  function load() {
    apiFetch<Bus[]>("/buses").then(setBuses).catch((e) => setError(e.message));
  }

  useEffect(load, []);

  async function addBus(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    try {
      await apiFetch<Bus>("/buses", {
        method: "POST",
        body: JSON.stringify({ registration_number: reg, capacity }),
      });
      setReg("");
      load();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to add bus");
    }
  }

  return (
    <div className="flex">
      <Sidebar />
      <main className="flex-1 px-10 py-8">
        <p className="font-display text-2xl font-semibold text-ink">Fleet</p>
        <p className="text-slate text-sm mt-1">Every bus registered under your operator account.</p>

        <form onSubmit={addBus} className="blueprint-frame bg-white/60 mt-6 px-5 py-4 flex items-end gap-3 max-w-lg">
          <label className="text-sm text-ink flex-1">
            Registration number
            <input
              required
              value={reg}
              onChange={(e) => setReg(e.target.value)}
              placeholder="KL-07-AB-1234"
              className="mt-1 w-full border border-line rounded px-3 py-2 bg-white outline-none focus:ring-2 focus:ring-rust"
            />
          </label>
          <label className="text-sm text-ink w-28">
            Capacity
            <input
              type="number"
              value={capacity}
              onChange={(e) => setCapacity(Number(e.target.value))}
              className="mt-1 w-full border border-line rounded px-3 py-2 bg-white outline-none focus:ring-2 focus:ring-rust"
            />
          </label>
          <button type="submit" className="bg-rust text-white px-4 py-2 rounded hover:bg-rustDark">
            Add bus
          </button>
        </form>

        {error && <p className="text-sm text-red-600 mt-4">{error}</p>}

        <div className="mt-8 divide-y divide-line border-t border-line max-w-2xl">
          {buses.map((bus) => (
            <div key={bus.id} className="flex items-center justify-between py-3">
              <span className="telemetry text-ink">{bus.registration_number}</span>
              <span className="text-sm text-slate">{bus.capacity} seats</span>
              <span className={`text-sm ${bus.active ? "text-good" : "text-slate/50"}`}>
                {bus.active ? "Active" : "Inactive"}
              </span>
            </div>
          ))}
          {buses.length === 0 && <p className="text-sm text-slate py-4">No buses yet — add your first one above.</p>}
        </div>
      </main>
    </div>
  );
}
