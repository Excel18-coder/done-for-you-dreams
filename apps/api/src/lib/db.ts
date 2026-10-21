import { PrismaClient } from "@prisma/client";

export const prisma = new PrismaClient({
  log: process.env.NODE_ENV === "development" ? ["warn", "error"] : ["error"],
});

// Structured JSON logger (one line per event, greppable in prod).
type Level = "info" | "warn" | "error";
export function log(level: Level, msg: string, meta?: Record<string, unknown>) {
  const line = JSON.stringify({ ts: new Date().toISOString(), level, msg, ...meta });
  (level === "error" ? console.error : level === "warn" ? console.warn : console.log)(line);
}
