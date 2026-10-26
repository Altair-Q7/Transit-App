"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { AUTH_REQUIRED_EVENT, hasToken } from "@/lib/api";

export default function AuthGuard({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const [authorized, setAuthorized] = useState(false);

  useEffect(() => {
    const redirectToLogin = () => {
      setAuthorized(false);
      router.replace("/login");
    };
    const handleStorage = (event: StorageEvent) => {
      if (event.key === "sarathy_token" && !event.newValue) redirectToLogin();
    };

    if (!hasToken()) {
      redirectToLogin();
      return;
    }

    setAuthorized(true);
    window.addEventListener(AUTH_REQUIRED_EVENT, redirectToLogin);
    window.addEventListener("storage", handleStorage);
    return () => {
      window.removeEventListener(AUTH_REQUIRED_EVENT, redirectToLogin);
      window.removeEventListener("storage", handleStorage);
    };
  }, [router]);

  if (!authorized) {
    return (
      <main className="min-h-screen flex items-center justify-center px-6 text-sm text-slate">
        Checking operator session…
      </main>
    );
  }

  return <>{children}</>;
}
