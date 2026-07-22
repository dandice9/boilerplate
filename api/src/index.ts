import { Hono } from "hono";
import { logger } from "hono/logger";
import { usersRoute } from "./routes/users";

const app = new Hono();

app.use("*", logger());

app.get("/", (c) => c.json({ status: "ok" }));

app.route("/users", usersRoute);

const port = Number(process.env.PORT ?? 3000);

export default {
  port,
  fetch: app.fetch,
};
