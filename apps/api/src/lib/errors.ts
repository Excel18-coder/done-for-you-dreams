import type { NextFunction, Request, Response } from "express";

// Consistent error envelope: { error: { code, message, details? } }
export class ApiError extends Error {
  constructor(
    public status: number,
    public code: string,
    message: string,
    public details?: unknown,
  ) {
    super(message);
  }
}

export const badRequest = (msg: string, details?: unknown) => new ApiError(400, "BAD_REQUEST", msg, details);
export const unauthorized = (msg = "Autenticación requerida") => new ApiError(401, "UNAUTHORIZED", msg);
export const forbidden = (msg = "No autorizado") => new ApiError(403, "FORBIDDEN", msg);
export const notFound = (msg = "No encontrado") => new ApiError(404, "NOT_FOUND", msg);
export const conflict = (msg: string) => new ApiError(409, "CONFLICT", msg);

export function errorHandler(err: unknown, _req: Request, res: Response, _next: NextFunction) {
  if (err instanceof ApiError) {
    res.status(err.status).json({ error: { code: err.code, message: err.message, details: err.details } });
    return;
  }
  // Zod errors surface as 400 with flattened details
  const anyErr = err as { issues?: unknown[]; message?: string };
  if (anyErr?.issues) {
    res.status(400).json({ error: { code: "VALIDATION", message: "Datos inválidos", details: anyErr.issues } });
    return;
  }
  console.error("[unhandled]", err);
  res.status(500).json({ error: { code: "INTERNAL", message: "Error interno" } });
}

export function notFoundHandler(_req: Request, res: Response) {
  res.status(404).json({ error: { code: "NOT_FOUND", message: "Ruta no encontrada" } });
}
