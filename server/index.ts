import Elysia, { MaybePromise } from "elysia";
import { Env } from "./types";
import * as cf from "@cloudflare/workers-types";
import { handleCron } from "./cron";

type waitUntil = (promise: Promise<unknown>) => Promise<void>;

const client = new Elysia({ prefix: "/api/v1" })
  .derive(
    { as: "global" },
    // @ts-expect-error
    async ({ waitUntil, env }) => {
      return {
        waitUntil: waitUntil as waitUntil,
        env: env as Env,
      };
    }
  )
  .get("/currencies", async ({ env }) => {
    return await env.KV.get("currencies");
  });

const run: cf.ExportedHandler<Env> = {
  async fetch(request: cf.Request, env: Env, ctx: cf.ExecutionContext) {
    let r = client.decorate({
      env: env,
      waitUntil: ctx.waitUntil.bind(ctx),
    });
    return r.fetch(
      request as any as Request
    ) as any as MaybePromise<cf.Response>;
  },
  scheduled: handleCron,
};

export default run;
