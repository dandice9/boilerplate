import type { Context, Next } from "hono";
import { verifyToken, type JwtPayload, type Role } from "../lib/jwt";

export type AuthedVariables = {
  authUser: JwtPayload;
};

export async function requireAuth(c: Context<{ Variables: AuthedVariables }>, next: Next) {
  const header = c.req.header("Authorization");
  const token = header?.startsWith("Bearer ") ? header.slice(7) : undefined;

  if (!token) {
    return c.json({ error: "Missing bearer token" }, 401);
  }

  try {
    const payload = await verifyToken(token);
    c.set("authUser", payload);
    await next();
  } catch {
    return c.json({ error: "Invalid or expired token" }, 401);
  }
}

export function requireRole(...roles: Role[]) {
  return async (c: Context<{ Variables: AuthedVariables }>, next: Next) => {
    const authUser = c.get("authUser");
    if (!roles.includes(authUser.role)) {
      return c.json({ error: "Forbidden" }, 403);
    }
    await next();
  };
}
