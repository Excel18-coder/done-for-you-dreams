import { Router } from "express";
import { z } from "zod";
import { prisma } from "../lib/db.js";
import { notFound } from "../lib/errors.js";

export const router = Router();

const requestSchema = z.object({
  name: z.string().min(2).max(120),
  company: z.string().max(160).optional().or(z.literal("")),
  email: z.string().email(),
  phone: z.string().min(6).max(30),
  origin: z.string().min(2).max(120),
  originCode: z.string().max(10).optional().or(z.literal("")),
  destination: z.string().min(2).max(120),
  destCode: z.string().max(10).optional().or(z.literal("")),
  tripType: z.enum(["ONE_WAY", "RETURN", "MULTI_LEG"]),
  departureAt: z.string().datetime(),
  returnAt: z.string().datetime().optional().nullable(),
  pax: z.coerce.number().int().min(1).max(19),
  baggage: z.string().max(400).optional().or(z.literal("")),
  aircraftPref: z.enum(["TURBOPROP", "LIGHT_JET", "MIDSIZE_JET", "SUPER_MIDSIZE_JET", "LARGE_CABIN_JET", "VIP_AIRLINER", "HELICOPTER"]).optional().nullable(),
  domestic: z.boolean().default(true),
  flexible: z.boolean().default(false),
  groundTransport: z.string().max(400).optional().or(z.literal("")),
  catering: z.string().max(600).optional().or(z.literal("")),
  notes: z.string().max(2000).optional().or(z.literal("")),
  contactMethod: z.enum(["EMAIL", "PHONE", "WHATSAPP"]).default("EMAIL"),
  consent: z.literal(true),
  // Anti-duplicate: client sends a fingerprint of the form session.
  formToken: z.string().min(8).max(64).optional(),
}).superRefine((val, ctx) => {
  if (val.tripType === "RETURN" && val.returnAt) {
    if (new Date(val.returnAt) <= new Date(val.departureAt)) {
      ctx.addIssue({ code: "custom", message: "La fecha de regreso debe ser posterior a la salida", path: ["returnAt"] });
    }
  }
});

function makeRef(date = new Date()) {
  const yy = String(date.getFullYear()).slice(2);
  const mm = String(date.getMonth() + 1).padStart(2, "0");
  const dd = String(date.getDate()).padStart(2, "0");
  const rand = Math.floor(Math.random() * 10000).toString().padStart(4, "0");
  return `REQ-${yy}${mm}${dd}-${rand}`;
}

// Public charter request: creates a real PostgreSQL record with a unique
// reference. Duplicate submissions within 24h are deduplicated by email+route+date.
router.post("/charter-requests", async (req, res, next) => {
  try {
    const data = requestSchema.parse(req.body);
    const dep = new Date(data.departureAt);

    const duplicate = await prisma.charterRequest.findFirst({
      where: {
        publicEmail: data.email.toLowerCase(),
        origin: data.origin,
        destination: data.destination,
        departureAt: dep,
        createdAt: { gte: new Date(Date.now() - 24 * 3600 * 1000) },
      },
      select: { reference: true },
    });
    if (duplicate) {
      res.status(409).json({ error: { code: "DUPLICATE", message: "Ya registramos una solicitud igual en las últimas 24 horas.", reference: duplicate.reference } });
      return;
    }

    // Attach to an existing customer when the email matches, so the request is
    // visible in the customer's history without manual matching.
    const customer = await prisma.customer.findFirst({ where: { email: data.email.toLowerCase() }, select: { id: true } });

    let reference = makeRef();
    for (let i = 0; i < 5; i++) {
      const clash = await prisma.charterRequest.findUnique({ where: { reference }, select: { id: true } });
      if (!clash) break;
      reference = makeRef();
    }

    const created = await prisma.charterRequest.create({
      data: {
        reference,
        customerId: customer?.id ?? null,
        publicName: data.name,
        publicEmail: data.email.toLowerCase(),
        publicPhone: data.phone,
        publicCompany: data.company || null,
        origin: data.origin,
        originCode: data.originCode || null,
        destination: data.destination,
        destCode: data.destCode || null,
        tripType: data.tripType,
        departureAt: dep,
        returnAt: data.returnAt ? new Date(data.returnAt) : null,
        pax: data.pax,
        baggage: data.baggage || null,
        aircraftPref: data.aircraftPref ?? null,
        domestic: data.domestic,
        flexible: data.flexible,
        groundTransport: data.groundTransport || null,
        catering: data.catering || null,
        notes: data.notes || null,
        contactMethod: data.contactMethod,
        consent: true,
        source: "WEBSITE",
      },
    });
    res.status(201).json({ ok: true, reference: created.reference, id: created.id });
  } catch (e) { next(e); }
});

// Status lookup by reference so the submitter can follow up without an account.
router.get("/charter-requests/:reference", async (req, res, next) => {
  try {
    const found = await prisma.charterRequest.findUnique({
      where: { reference: req.params.reference },
      select: { reference: true, status: true, origin: true, destination: true, departureAt: true, pax: true, createdAt: true },
    });
    if (!found) return next(notFound("No encontramos esa referencia"));
    res.json({ request: found });
  } catch (e) { next(e); }
});
