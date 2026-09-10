import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./app/**/*.{ts,tsx}", "./components/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        ink: "#1B2A38",       // deep blueprint navy — primary text & chrome
        slate: "#43586B",     // secondary navy, muted
        paper: "#F6F4EE",     // warm blueprint-paper background
        line: "#C9D3D6",      // hairline grid / borders
        rust: "#C97B4A",      // signal accent — status, primary actions
        rustDark: "#A9613A",
        good: "#4C7A5E",
      },
      fontFamily: {
        display: ["var(--font-display)"],
        body: ["var(--font-body)"],
      },
    },
  },
  plugins: [],
};
export default config;
