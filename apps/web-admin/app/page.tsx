import Link from "next/link";

export default function Home() {
  return (
    <main className="min-h-screen flex items-center justify-center px-6">
      <div className="blueprint-frame max-w-md w-full bg-white/70 px-8 py-10 text-center">
        <p className="font-display text-3xl font-semibold text-ink">Sarathy</p>
        <p className="text-rust mt-1">Your journey, guided.</p>
        <p className="text-slate mt-6 text-sm leading-relaxed">
          The operator console for fleet visibility, live trip monitoring,
          and passenger-facing ETA accuracy.
        </p>
        <Link
          href="/login"
          className="inline-block mt-8 bg-ink text-paper px-6 py-2.5 rounded hover:bg-slate transition-colors"
        >
          Sign in to your console
        </Link>
      </div>
    </main>
  );
}
