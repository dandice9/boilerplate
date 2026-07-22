import { Hono } from "hono";
import { eq } from "drizzle-orm";
import { db, users } from "@boilerplate/database";

export const usersRoute = new Hono();

usersRoute.get("/", async (c) => {
  const allUsers = await db.select().from(users);
  return c.json(allUsers);
});

usersRoute.get("/:id", async (c) => {
  const id = Number(c.req.param("id"));
  const [user] = await db.select().from(users).where(eq(users.id, id));

  if (!user) {
    return c.json({ error: "User not found" }, 404);
  }

  return c.json(user);
});

usersRoute.post("/", async (c) => {
  const body = await c.req.json<{ email: string; name: string }>();
  const [created] = await db.insert(users).values(body).returning();
  return c.json(created, 201);
});

usersRoute.delete("/:id", async (c) => {
  const id = Number(c.req.param("id"));
  await db.delete(users).where(eq(users.id, id));
  return c.body(null, 204);
});
