import { Router } from "express";
import { randomBytes } from "node:crypto";
import { z } from "zod";
import { prisma } from "../lib/db.js";
import { badRequest, unauthorized } from "../lib/errors.js";
import {
  audit, clearSessionCookie, createSession, hashPassword, logoutSession,
  requireAuth, setSessionCookie, verifyPassword,
} from "../lib/auth.js";
import { sendEmail } from "../lib/email.js";
import { env } from "../config/env.js";

export const router = Router();

const loginSchema = z.object({ email: z.string().email(), password: z.string().min(1) });

router.post("/login", async (req, res, next) => {
  try {
    const { email, password } = loginSchema.parse(req.body);
    const user = await prisma.user.findUnique({ where: { email: email.toLowerCase().trim() } });
    const ok = user && user.active && (await verifyPassword(password, user.passwordHash));
    if (!user || !ok) {
      // Same error for unknown user and wrong password.
      return next(unauthorized("Credenciales inválidas"));
    }
    const { token, expiresAt } = await createSession(user.id, req.ip, req.headers["user-agent"]);
    setSessionCookie(res, token, expiresAt);
    await audit(req, "LOGIN", "User", user.id);
    res.json({ user: { id: user.id, email: user.email, name: user.name, role: user.role, operatorId: user.operatorId, customerId: user.customerId } });
  } catch (e) { next(e); }
});

router.post("/logout", async (req, res, next) => {
  try {
    await logoutSession(req);
    clearSessionCookie(res);
    res.json({ ok: true });
  } catch (e) { next(e); }
});

router.get("/me", requireAuth, (req, res) => {
  res.json({ user: req.user });
});

const changeSchema = z.object({ currentPassword: z.string(), newPassword: z.string().min(10) });
router.post("/change-password", requireAuth, async (req, res, next) => {
  try {
    const { currentPassword, newPassword } = changeSchema.parse(req.body);
    const user = await prisma.user.findUniqueOrThrow({ where: { id: req.user!.id } });
    if (!(await verifyPassword(currentPassword, user.passwordHash))) return next(unauthorized("Contraseña actual incorrecta"));
    await prisma.user.update({ where: { id: user.id }, data: { passwordHash: await hashPassword(newPassword) } });
    // Revoke all other sessions after a password change.
    await prisma.session.updateMany({ where: { userId: user.id, revokedAt: null }, data: { revokedAt: new Date() } });
    await audit(req, "PASSWORD_CHANGE", "User", user.id);
    const { token, expiresAt } = await createSession(user.id, req.ip, req.headers["user-agent"]);
    setSessionCookie(res, token, expiresAt);
    res.json({ ok: true });
  } catch (e) { next(e); }
});

const forgotSchema = z.object({ email: z.string().email() });
router.post("/forgot-password", async (req, res, next) => {
  try {
    const { email } = forgotSchema.parse(req.body);
    const user = await prisma.user.findUnique({ where: { email: email.toLowerCase().trim() } });
    if (user) {
      const token = randomBytes(24).toString("hex");
      await prisma.user.update({
        where: { id: user.id },
        data: { resetToken: token, resetExpiresAt: new Date(Date.now() + 60 * 60 * 1000) },
      });
      const base = env.FRONTEND_ORIGIN.split(",")[0].trim();
      const result = await sendEmail({
        to: user.email,
        subject: "Restablecer contraseña",
        text: `Usa este enlace para restablecer tu contraseña (válido 1 hora): ${base}/reset-password?token=${token}`,
        template: "password-reset",
      });
      if (!result.sent) {
        // Never pretend it was sent: surface the manual fallback.
        res.json({ ok: true, emailSent: false, message: "El proveedor de correo no está configurado. Solicita el enlace a un administrador." });
        return;
      }
    }
    res.json({ ok: true, emailSent: true });
  } catch (e) { next(e); }
});

const resetSchema = z.object({ token: z.string().min(10), newPassword: z.string().min(10) });
router.post("/reset-password", async (req, res, next) => {
  try {
    const { token, newPassword } = resetSchema.parse(req.body);
    const user = await prisma.user.findFirst({
      where: { resetToken: token, resetExpiresAt: { gt: new Date() }, active: true },
    });
    if (!user) return next(badRequest("Token inválido o expirado"));
    await prisma.user.update({
      where: { id: user.id },
      data: { passwordHash: await hashPassword(newPassword), resetToken: null, resetExpiresAt: null },
    });
    await prisma.session.updateMany({ where: { userId: user.id, revokedAt: null }, data: { revokedAt: new Date() } });
    await audit({ user: undefined } as never, "PASSWORD_RESET", "User", user.id).catch(() => {});
    res.json({ ok: true });
  } catch (e) { next(e); }
});
