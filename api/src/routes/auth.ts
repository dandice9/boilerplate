import { Hono } from "hono";
import { and, eq } from "drizzle-orm";
import { db, users, type User } from "@boilerplate/database";
import { isRole, signToken } from "../lib/jwt";
import { requireAuth, type AuthedVariables } from "../middleware/auth";

function toPublicUser(user: User) {
  const { passwordHash, ...publicUser } = user;
  return publicUser;
}

export const authRoute = new Hono<{ Variables: AuthedVariables }>();

authRoute.post("/register", async (c) => {
  const body = await c.req.json<{ email?: string; password?: string; name?: string; role?: string }>();
  const { email, password, name, role } = body;

  if (!email || !password || !name || !isRole(role)) {
    return c.json({ error: "email, password, name and a valid role are required" }, 400);
  }
  if (password.length < 8) {
    return c.json({ error: "password must be at least 8 characters" }, 400);
  }

  const [existing] = await db
    .select({ id: users.id })
    .from(users)
    .where(and(eq(users.email, email), eq(users.role, role)));

  if (existing) {
    return c.json({ error: "An account with this email already exists for this role" }, 409);
  }

  const passwordHash = await Bun.password.hash(password);
  const [created] = await db.insert(users).values({ email, name, role, passwordHash }).returning();

  const token = await signToken({ sub: created.id, role: created.role });
  return c.json({ token, user: toPublicUser(created) }, 201);
});

authRoute.post("/login", async (c) => {
  const body = await c.req.json<{ email?: string; password?: string; role?: string }>();
  const { email, password, role } = body;

  if (!email || !password || !isRole(role)) {
    return c.json({ error: "email, password and a valid role are required" }, 400);
  }

  const [user] = await db
    .select()
    .from(users)
    .where(and(eq(users.email, email), eq(users.role, role)));

  if (!user || !(await Bun.password.verify(password, user.passwordHash))) {
    return c.json({ error: "Invalid email or password" }, 401);
  }

  const token = await signToken({ sub: user.id, role: user.role });
  return c.json({ token, user: toPublicUser(user) });
});

authRoute.get("/me", requireAuth, async (c) => {
  const authUser = c.get("authUser");
  const [user] = await db.select().from(users).where(eq(users.id, Number(authUser.sub)));

  if (!user) {
    return c.json({ error: "User not found" }, 404);
  }

  return c.json({ user: toPublicUser(user) });
});

// JWTs are stateless, so logout is really the client discarding its token.
// This endpoint exists for symmetry and as a hook for future server-side revocation.
authRoute.post("/logout", requireAuth, async (c) => {
  return c.body(null, 204);
});
