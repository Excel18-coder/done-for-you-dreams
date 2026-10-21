import { prisma } from "./db.js";
import { emailConfigured, env } from "../config/env.js";

/**
 * Sends an email through the configured provider (Resend API) and records the
 * delivery in EmailLog. If no provider is configured the record is stored with
 * status NOT_CONFIGURED — the caller must treat it as "not sent" and fall back
 * to manual workflows (copy-to-clipboard, WhatsApp click-to-chat).
 */
export async function sendEmail(opts: { to: string; subject: string; text: string; template?: string; meta?: Record<string, unknown> }) {
  const record = await prisma.emailLog.create({
    data: {
      toAddress: opts.to,
      subject: opts.subject,
      template: opts.template,
      status: emailConfigured ? "QUEUED" : "NOT_CONFIGURED",
      provider: emailConfigured ? "resend" : "log",
      meta: opts.meta ?? {},
    },
  });
  if (!emailConfigured) return { ok: false, recordId: record.id, sent: false as const };

  try {
    const resp = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${env.EMAIL_PROVIDER_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: env.EMAIL_FROM_ADDRESS || "no-reply@example.com",
        to: [opts.to],
        subject: opts.subject,
        text: opts.text,
      }),
    });
    if (resp.ok) {
      await prisma.emailLog.update({ where: { id: record.id }, data: { status: "SENT", sentAt: new Date() } });
      return { ok: true, recordId: record.id, sent: true as const };
    }
    const body = await resp.text().catch(() => "");
    await prisma.emailLog.update({ where: { id: record.id }, data: { status: "FAILED", error: body.slice(0, 500) } });
    return { ok: false, recordId: record.id, sent: false as const };
  } catch (e) {
    await prisma.emailLog.update({ where: { id: record.id }, data: { status: "FAILED", error: String(e).slice(0, 500) } });
    return { ok: false, recordId: record.id, sent: false as const };
  }
}

export const emailNotConfiguredMessage =
  "El proveedor de correo no está configurado. La comunicación queda registrada como manual: copia el mensaje y envíalo por tu correo o WhatsApp.";
