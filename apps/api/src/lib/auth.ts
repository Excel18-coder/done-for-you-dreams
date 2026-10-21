import { createHash, randomBytes, timingSafeEqual } from "node:crypto";
import type { NextFunction, Request, Response } from "express";
import type { AppRole } from "@prisma/client";
import { hash, verify } from "@node-rs/argon2";
import { prisma } from "./db.js";
import { forbidden, unauthorized } from "./errors.js";
import { env } from "../config/env.js";

const COOKIE = "av_sid";
const SESSION_DAYS = 7;

export async function hashPassword(pw: string) {
  // Argon2id with sane defaults (19MiB, t=2, p=1 per OWASP).
  return hash(pw, { algorithm: 2 });
}
export async function verifyPassword(pw: string, hashStr: string) {
  try {
    return await verify(hashStr, pw);
  } catch {
    return false;
  }
}

const sha256 = (s: string) => createHash("sha256").update(s).digest("hex");

export async function createSession(userId: string, ip?: string, userAgent?: string) {
  const token = randomBytes(32).toString("hex");
  const expiresAt = new Date(Date.now() + SESSION_DAYS * 24 * 3600 * 1000);
  await prisma.session.create({
    data: { tokenHash: sha256(token), userId, ip, userAgent, expiresAt },
  });
  return { token, expiresAt };
}

export function setSessionCookie(res: Response, token: string, expiresAt: Date) {
  res.cookie(COOKIE, token, {
    httpOnly: true,
    sameSite: "lax", // CSRF baseline; origin check below adds defense in depth
    secure: env.NODE_ENV === "production",
    path: "/",
    expires: expiresAt,
  });
}
export function clearSessionCookie(res: Response) {
  res.clearCookie(COOKIE, { httpOnly: true, sameSite: "lax", path: "/" });
}

// CSRF defense: for state-changing requests with an Origin header, the origin
// must be an approved frontend origin or the API's own host.
export function originCheck(req: Request, res: Response, next: NextFunction) {
  if (req.method === "GET" || req.method === "HEAD" || req.method === "OPTIONS") return next();
  const origin = req.headers.origin;
  if (!origin) return next(); // same-origin requests without Origin (curl, server-side)
  const allowed = new Set(env.FRONTEND_ORIGIN.split(",").map((s) => s.trim()));
  if (origin === `http://localhost:${env.PORT}`) return next();
  if (allowed.has(origin)) return next();
  res.status(403).json({ error: { code: "FORBIDDEN", message: "Origen no permitido" } });
}

declare module "express-serve-static-core" {
  interface Request {
    user?: { id: string; email: string; name: string; role: AppRole; operatorId: string | null; customerId: string | null };
    sessionId?: string;
  }
}

export async function requireAuth(req: Request, res: Response, next: NextFunction) {
  const token = (req.cookies?.[COOKIE] as string | undefined) ?? "";
  if (!token) return next(unauthorized());
  const session = await prisma.session.findUnique({
    where: { tokenHash: sha256(token) },
    include: { user: true },
  });
  if (!session || session.revokedAt || session.expiresAt < new Date() || !session.user.active) {
    return next(unauthorized());
  }
  req.user = {
    id: session.user.id,
    email: session.user.email,
    name: session.user.name,
    role: session.user.role,
    operatorId: session.user.operatorId,
    customerId: session.user.customerId,
  };
  req.sessionId = session.id;
  next();
}

export function requireRole(...roles: AppRole[]) {
  return (req: Request, _res: Response, next: NextFunction) => {
    if (!req.user) return next(unauthorized());
    if (!roles.includes(req.user.role)) return next(forbidden());
    next();
  };
}

const STAFF: AppRole[] = ["SUPER_ADMIN", "BROKERAGE_ADMIN", "SALES", "CHARTER_OPS", "FINANCE"];
export const isStaff = (role: AppRole) => STAFF.includes(role);
// Roles allowed to see internal margins / supplier negotiation data
const MARGIN_ROLES: AppRole[] = ["SUPER_ADMIN", "BROKERAGE_ADMIN", "FINANCE"];
export const canSeeMargins = (role: AppRole) => MARGIN_ROLES.includes(role);
// Roles that can approve verification / proposals
export const ADMIN_ROLES: AppRole[] = ["SUPER_ADMIN", "BROKERAGE_ADMIN"];

export async function logoutSession(req: Request) {
  const token = (req.cookies?.[COOKIE] as string | undefined) ?? "";
  if (token) {
    await prisma.session.updateMany({
      where: { tokenHash: sha256(token), revokedAt: null },
      data: { revokedAt: new Date() },
    });
  }
}

export function safeEqual(a: string, b: string) {
  const ba = Buffer.from(a);
  const bb = Buffer.from(b);
  return ba.length === bb.length && timingSafeEqual(ba, bb);
}

/** Audit log for sensitive actions (append-only). */
export async function audit(req: Request, action: string, entity?: string, entityId?: string, detail?: Record<string, unknown>) {
  await prisma.auditLog.create({
    data: { userId: req.user?.id ?? null, action, entity, entityId, detail: detail ?? {} },
  });
}
