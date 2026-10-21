import { z } from "zod";

const schema = z.object({
  NODE_ENV: z.enum(["development", "production", "test"]).default("development"),
  PORT: z.coerce.number().default(4000),
  DATABASE_URL: z.string().min(1, "DATABASE_URL es obligatorio"),
  SESSION_SECRET: z.string().min(16, "SESSION_SECRET debe tener al menos 16 caracteres"),
  FRONTEND_ORIGIN: z.string().default("http://localhost:8080"),
  EMAIL_PROVIDER_API_KEY: z.string().optional().default(""),
  EMAIL_FROM_ADDRESS: z.string().optional().default(""),
  SMTP_HOST: z.string().optional().default(""),
  SMTP_PORT: z.coerce.number().optional(),
  SMTP_USER: z.string().optional().default(""),
  SMTP_PASSWORD: z.string().optional().default(""),
  OBJECT_STORAGE_ENDPOINT: z.string().optional().default(""),
  OBJECT_STORAGE_REGION: z.string().optional().default(""),
  OBJECT_STORAGE_BUCKET: z.string().optional().default(""),
  OBJECT_STORAGE_ACCESS_KEY: z.string().optional().default(""),
  OBJECT_STORAGE_SECRET_KEY: z.string().optional().default(""),
  OBJECT_STORAGE_PUBLIC_BASE_URL: z.string().optional().default(""),
});

const parsed = schema.safeParse(process.env);
if (!parsed.success) {
  console.error("[config] Variables de entorno inválidas:", parsed.error.flatten().fieldErrors);
  process.exit(1);
}

export const env = parsed.data;
export const emailConfigured = Boolean(
  env.EMAIL_PROVIDER_API_KEY || (env.SMTP_HOST && env.SMTP_USER),
);
export const storageConfigured = Boolean(
  env.OBJECT_STORAGE_ENDPOINT && env.OBJECT_STORAGE_BUCKET && env.OBJECT_STORAGE_ACCESS_KEY,
);
