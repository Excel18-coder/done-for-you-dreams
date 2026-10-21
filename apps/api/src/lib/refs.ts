import { randomInt } from "node:crypto";

/** REQ-YYMMDD-NNNN style unique references. */
export function makeRef(prefix: string, date = new Date()) {
  const yy = String(date.getFullYear()).slice(2);
  const mm = String(date.getMonth() + 1).padStart(2, "0");
  const dd = String(date.getDate()).padStart(2, "0");
  const rand = String(randomInt(0, 10000)).padStart(4, "0");
  return `${prefix}-${yy}${mm}${dd}-${rand}`;
}

/** Standard pagination parsing for list endpoints. */
export function pagination(q: Record<string, unknown>) {
  const page = Math.max(1, Number(q.page ?? 1) || 1);
  const pageSize = Math.min(100, Math.max(1, Number(q.pageSize ?? 25) || 25));
  return { skip: (page - 1) * pageSize, take: pageSize, page, pageSize };
}
