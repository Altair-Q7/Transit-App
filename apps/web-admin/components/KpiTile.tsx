export default function KpiTile({
  label,
  value,
  hint,
}: {
  label: string;
  value: string | number;
  hint?: string;
}) {
  return (
    <div className="blueprint-frame bg-white/60 px-5 py-4">
      <p className="text-sm text-slate/70">{label}</p>
      <p className="font-display text-3xl font-semibold text-ink mt-1 telemetry">{value}</p>
      {hint && <p className="text-xs text-slate/60 mt-1">{hint}</p>}
    </div>
  );
}
