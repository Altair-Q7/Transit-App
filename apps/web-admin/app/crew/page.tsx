"use client";

import { useCallback, useEffect, useState } from "react";
import Sidebar from "@/components/Sidebar";
import AuthGuard from "@/components/AuthGuard";
import { createCrew, listCrew, type Crew, type CrewInput } from "@/lib/api";

export default function CrewPage() {
  const [crew, setCrew] = useState<Crew[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [creating, setCreating] = useState(false);
  const [form, setForm] = useState<CrewInput>({ name: "", phone: "", password: "", role: "driver" });

  const loadCrew = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      setCrew(await listCrew());
    } catch (err) {
      setError(err instanceof Error ? err.message : "Could not load crew roster");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void loadCrew();
  }, [loadCrew]);

  const handleChange = (key: keyof CrewInput) => (
    event: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>,
  ) => {
    setForm((current) => ({ ...current, [key]: event.target.value as CrewInput[keyof CrewInput] }));
  };

  const handleCreate = async (event: React.FormEvent) => {
    event.preventDefault();
    setError(null);
    setCreating(true);
    try {
      const created = await createCrew(form);
      setCrew((current) => [created, ...current]);
      setForm({ name: "", phone: "", password: "", role: "driver" });
    } catch (err) {
      const message = err instanceof Error ? err.message : "Could not create crew member";
      if (err instanceof Error && err.name === "ApiError409") {
        setError("A crew member with this phone number already exists.");
      } else {
        setError(message);
      }
    } finally {
      setCreating(false);
    }
  };

  return (
    <AuthGuard>
      <div className="flex">
        <Sidebar />
        <main className="flex-1 px-10 py-8">
          <div className="flex items-start justify-between gap-4">
            <div>
              <p className="font-display text-2xl font-semibold text-ink">Crew</p>
              <p className="text-slate text-sm mt-1">
                Drivers and conductors who start trips and report incidents.
              </p>
            </div>
          </div>

          {error && (
            <div className="bg-red-50 mt-8 px-5 py-4 text-sm text-red-700 border border-red-100 rounded">
              <p>{error}</p>
            </div>
          )}

          {loading && !error && (
            <div className="bg-white/60 mt-8 px-5 py-8 text-sm text-slate border border-line rounded">
              Loading crew roster…
            </div>
          )}

          {!loading && !error && crew.length === 0 && (
            <div className="bg-white/60 mt-8 px-5 py-8 border border-line rounded">
              <p className="font-display text-lg font-semibold text-ink">No crew members yet</p>
              <p className="text-sm text-slate mt-1">
                Add a driver or conductor using the form below.
              </p>
            </div>
          )}

          {!loading && !error && crew.length > 0 && (
            <div className="blueprint-frame bg-white/70 mt-8 overflow-x-auto sm:overflow-visible">
              <table className="w-full text-sm text-left border-collapse">
                <thead>
                  <tr className="border-b border-line text-slate">
                    <th className="px-4 py-3">ID</th>
                    <th className="px-4 py-3">Name</th>
                    <th className="px-4 py-3">Phone</th>
                    <th className="px-4 py-3">Role</th>
                  </tr>
                </thead>
                <tbody>
                  {crew.map((member) => (
                    <tr key={member.id} className="border-b border-line bg-white/60">
                      <td className="px-4 py-3 telemetry">{member.id}</td>
                      <td className="px-4 py-3 text-ink">{member.name}</td>
                      <td className="px-4 py-3 text-slate/70 telemetry">{member.phone}</td>
                      <td className="px-4 py-3">
                        <span
                          className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold uppercase tracking-wide ${
                            member.role === "driver" ? "bg-good/10 text-good" : "bg-ink/10 text-ink"
                          }`}
                        >
                          {member.role}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}

          <section className="blueprint-frame bg-white/70 mt-8 max-w-xl px-5 py-5">
            <p className="font-display text-lg font-semibold text-ink">Add crew member</p>
            <p className="text-slate text-sm mt-1">
              Phone numbers must be unique across the crew roster.
            </p>
            <form onSubmit={handleCreate} className="mt-5 flex flex-col sm:flex-row gap-3 items-end">
              <div className="flex-1 min-w-0">
                <label className="text-sm text-ink block">Name</label>
                <input
                  name="name"
                  type="text"
                  autoComplete="name"
                  required
                  value={form.name}
                  onChange={handleChange("name")}
                  className="mt-1 w-full border border-line rounded px-3 py-2 bg-white outline-none focus:ring-2 focus:ring-rust"
                />
              </div>
              <div className="flex-1 min-w-0">
                <label className="text-sm text-ink block">Phone</label>
                <input
                  name="phone"
                  type="tel"
                  autoComplete="tel"
                  required
                  value={form.phone}
                  onChange={handleChange("phone")}
                  className="mt-1 w-full border border-line rounded px-3 py-2 bg-white outline-none focus:ring-2 focus:ring-rust"
                />
              </div>
              <div className="flex-1 min-w-0">
                <label className="text-sm text-ink block">Password</label>
                <input
                  name="password"
                  type="password"
                  autoComplete="new-password"
                  required
                  minLength={6}
                  value={form.password}
                  onChange={handleChange("password")}
                  className="mt-1 w-full border border-line rounded px-3 py-2 bg-white outline-none focus:ring-2 focus:ring-rust"
                />
              </div>
              <div className="flex-1 min-w-0">
                <label className="text-sm text-ink block">Role</label>
                <select
                  name="role"
                  required
                  value={form.role}
                  onChange={handleChange("role")}
                  className="mt-1 w-full border border-line rounded px-3 py-2 bg-white outline-none focus:ring-2 focus:ring-rust"
                >
                  <option value="driver">Driver</option>
                  <option value="conductor">Conductor</option>
                </select>
              </div>
              <button
                type="submit"
                disabled={creating}
                className="bg-rust text-white px-4 py-2 rounded hover:bg-rustDark disabled:opacity-60"
              >
                {creating ? "Adding…" : "Add crew member"}
              </button>
            </form>
            <p className="text-xs text-slate/70 mt-3 max-w-sm">
              Creation uses <span className="telemetry">POST /operator/crew</span>; a duplicate phone returns a 409 conflict.
            </p>
          </section>
        </main>
      </div>
    </AuthGuard>
  );
}
