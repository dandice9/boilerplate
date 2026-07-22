import { Hono } from "hono";
import { db, users, type User } from "@boilerplate/database";
import { requireAuth, requireRole, type AuthedVariables } from "../middleware/auth";

function toPublicUser(user: User) {
  const { passwordHash, ...publicUser } = user;
  return publicUser;
}

export const usersRoute = new Hono<{ Variables: AuthedVariables }>();

// Listing every account is an admin (management) capability, not something
// the customer/vendor apps need for their own single-user dashboards.
usersRoute.use("*", requireAuth, requireRole("management"));

usersRoute.get("/", async (c) => {
  const allUsers = await db.select().from(users);
  return c.json(allUsers.map(toPublicUser));
});
