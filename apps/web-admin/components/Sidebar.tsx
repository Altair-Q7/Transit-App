"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const links = [
  { href: "/dashboard", label: "Overview" },
  { href: "/buses", label: "Fleet" },
  { href: "/routes", label: "Routes & Stops" },
  { href: "/trips", label: "Live Trips" },
];

export default function Sidebar() {
  const pathname = usePathname();

  return (
    <aside className="w-56 shrink-0 border-r border-line bg-ink text-paper/90 min-h-screen">
      <div className="px-6 py-6 border-b border-white/10">
        <p className="font-display text-lg font-semibold text-paper">Sarathy</p>
        <p className="text-xs text-paper/50 mt-0.5">Operator Console</p>
      </div>
      <nav className="px-3 py-4 flex flex-col gap-1">
        {links.map((link) => {
          const active = pathname?.startsWith(link.href);
          return (
            <Link
              key={link.href}
              href={link.href}
              className={`px-3 py-2 rounded text-sm transition-colors ${
                active ? "bg-rust text-white" : "text-paper/70 hover:bg-white/5 hover:text-paper"
              }`}
            >
              {link.label}
            </Link>
          );
        })}
      </nav>
    </aside>
  );
}
