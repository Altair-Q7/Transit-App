"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { loginOperator } from "@/lib/api";

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      await loginOperator(email, password);
      router.push("/dashboard");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Something went wrong");
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className="min-h-screen flex items-center justify-center px-6">
      <form onSubmit={handleSubmit} className="blueprint-frame w-full max-w-sm bg-white/70 px-8 py-9">
        <p className="font-display text-xl font-semibold text-ink">Operator sign in</p>
        <p className="text-sm text-slate mt-1">Access your fleet and live trip data.</p>

        <label className="block mt-6 text-sm text-ink">
          Email
          <input
            type="email"
            required
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="mt-1 w-full border border-line rounded px-3 py-2 bg-white outline-none focus:ring-2 focus:ring-rust"
          />
        </label>

        <label className="block mt-4 text-sm text-ink">
          Password
          <input
            type="password"
            required
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            className="mt-1 w-full border border-line rounded px-3 py-2 bg-white outline-none focus:ring-2 focus:ring-rust"
          />
        </label>

        {error && <p className="text-sm text-red-600 mt-4">{error}</p>}

        <button
          type="submit"
          disabled={loading}
          className="mt-6 w-full bg-rust text-white py-2.5 rounded hover:bg-rustDark transition-colors disabled:opacity-60"
        >
          {loading ? "Signing in…" : "Sign in"}
        </button>
      </form>
    </main>
  );
}
