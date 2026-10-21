import express from "express";
import helmet from "helmet";
import cors from "cors";
import cookieParser from "cookie-parser";
import rateLimit from "express-rate-limit";
import { env } from "./config/env.js";
import { errorHandler, notFoundHandler } from "./lib/errors.js";
import { originCheck } from "./lib/auth.js";

import { router as authRoutes } from "./routes/auth.js";
import { router as publicRoutes } from "./routes/public.js";
import { router as crmRoutes } from "./routes/crm.js";
import { router as operatorRoutes } from "./routes/operators.js";
import { router as requestRoutes } from "./routes/requests.js";
import { router as rfqRoutes } from "./routes/rfqs.js";
import { router as proposalRoutes } from "./routes/proposals.js";
import { router as bookingRoutes } from "./routes/bookings.js";
import { router as financeRoutes } from "./routes/finance.js";
import { router as workflowRoutes } from "./routes/workflow.js";
import { router as adminRoutes } from "./routes/admin.js";

const app = express();
app.set("trust proxy", 1);
app.use(helmet());
app.use(cors({ origin: env.FRONTEND_ORIGIN.split(",").map((s) => s.trim()), credentials: true }));
app.use(express.json({ limit: "2mb" }));
app.use(cookieParser());
app.use(originCheck);

// Health: readiness without leaking infrastructure details.
app.get("/health", (_req, res) => {
  res.json({ ok: true, version: "0.1.0" });
});

const globalLimiter = rateLimit({ windowMs: 60_000, limit: 300, standardHeaders: "draft-7", legacyHeaders: false });
const authLimiter = rateLimit({ windowMs: 15 * 60_000, limit: 20, standardHeaders: "draft-7", legacyHeaders: false });
const publicFormLimiter = rateLimit({ windowMs: 10 * 60_000, limit: 10, standardHeaders: "draft-7", legacyHeaders: false });

app.use("/api/v1/auth", authLimiter, authRoutes);
app.use("/api/v1/public", publicFormLimiter, publicRoutes);
app.use("/api/v1", globalLimiter, crmRoutes);
app.use("/api/v1", globalLimiter, operatorRoutes);
app.use("/api/v1", globalLimiter, requestRoutes);
app.use("/api/v1", globalLimiter, rfqRoutes);
app.use("/api/v1", globalLimiter, proposalRoutes);
app.use("/api/v1", globalLimiter, bookingRoutes);
app.use("/api/v1", globalLimiter, financeRoutes);
app.use("/api/v1", globalLimiter, workflowRoutes);
app.use("/api/v1", globalLimiter, adminRoutes);

app.use(notFoundHandler);
app.use(errorHandler);

app.listen(env.PORT, () => {
  console.log(JSON.stringify({ ts: new Date().toISOString(), level: "info", msg: `API listening on :${env.PORT}` }));
});
