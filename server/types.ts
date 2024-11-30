import { t } from "elysia";

export const currenciesResponse = {
  200: t.Object({
    sources: t.Array(
      t.Object({
        name: t.String(),
        lastUpdate: t.String(),
      })
    ),
    data: t.Record(t.String(), t.Record(t.String(), t.Number()), {
      description:
        "Maps base currency to exchange rates, base currency is `eur`",
    }),
  }),
  401: t.Object({
    message: t.Literal("Unauthorized"),
  }),
};
