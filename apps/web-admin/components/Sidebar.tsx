"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { AUTH_REQUIRED_EVENT, clearToken, hasToken } from "@/lib/api";

const links = [
  { href: "/dashboard", label: "Overview" },
  { href: "/buses", label: "Fleet" },
  { href: "/routes", label: "Routes & Stops" },
  { href: "/trips", label: "Live Trips" },
  { href: "/incidents", label: "Incidents" },
];

export default function Sidebar() {
  const pathname = usePathname();
  const router = useRouter();
  const [authorized, setAuthorized] = useState(false);

  useEffect(() => {
    const goToLogin = () => {
      setAuthorized(false);
      router.replace("/login");
    };

    if (!hasToken()) {
      goToLogin();
      return;
    }

    setAuthorized(true);
    window.addEventListener(AUTH_REQUIRED_EVENT, goToLogin);
    const handleStorage = (event: StorageEvent) => {
      if (event.key === "sarathy_token" && !event.newValue) goToLogin();
    };
    window.addEventListener("storage", handleStorage);
    return () => {
      window.removeEventListener(AUTH_REQUIRED_EVENT, goToLogin);
      window.removeEventListener("storage", handleStorage);
    };
  }, [router]);

  function logout() {
    clearToken();
    router.replace("/login");
  }

  if (!authorized) return null;

  return (
    <aside className="w-56 shrink-0 border-r border-line bg-ink text-paper/90 min-h-screen flex flex-col">
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
      <div className="mt-auto px-3 pb-5">
        <button
          type="button"
          onClick={logout}
          className="w-full px-3 py-2 rounded text-left text-sm text-paper/70 hover:bg-white/5 hover:text-paper transition-colors"
        >
          Sign out
        </button>
      </div>
    </aside>
  );
}
