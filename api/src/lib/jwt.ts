import { sign, verify } from "hono/jwt";

export const ROLES = ["customer", "vendor", "management"] as const;
export type Role = (typeof ROLES)[number];

export type JwtPayload = {
  sub: string;
  role: Role;
  exp: number;
};

const secret = process.env.JWT_SECRET;
if (!secret) {
  throw new Error("JWT_SECRET is not set");
}

const TOKEN_TTL_SECONDS = 60 * 60 * 24 * 7; // 7 days

export function isRole(value: unknown): value is Role {
  return typeof value === "string" && (ROLES as readonly string[]).includes(value);
}

export function signToken(payload: { sub: number; role: Role }) {
  const exp = Math.floor(Date.now() / 1000) + TOKEN_TTL_SECONDS;
  return sign({ sub: String(payload.sub), role: payload.role, exp }, secret);
}

export function verifyToken(token: string) {
  return verify(token, secret, "HS256") as Promise<JwtPayload>;
}
