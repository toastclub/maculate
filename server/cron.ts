import { Env } from "./types";

interface FawazReturn {
  date: string;
  eur: {
    [key: string]: number;
  };
}

async function fetchFawazCurrencyData(): Promise<FawazReturn | undefined> {
  const urls = [
    "https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/eur.min.json",
    "https://latest.currency-api.pages.dev/v1/currencies/eur.min.json",
  ];

  for (const url of urls) {
    try {
      const response = await fetch(url);
      if (response.ok) {
        return await response.json();
      } else {
        console.error(
          `Failed to fetch from ${url}: ${response.status} ${response.statusText}`
        );
      }
    } catch (error) {
      console.error(`Error fetching from ${url}:`, error);
    }
  }
}

interface OpenExchangeRatesReturn {
  timestamp: number;
  base: string;
  success: boolean;
  rates: {
    [key: string]: number;
  };
}

async function fetchOpenExchangeRatesData(): Promise<FawazReturn | undefined> {
  const json: OpenExchangeRatesReturn = await (
    await fetch("https://open.er-api.com/v6/latest/EUR")
  ).json();
  if (!json?.success) {
    console.error(`Failed to fetch from OpenExchangeRates: ${json.error.type}`);
    return undefined;
  }
  if (json?.rates?.EUR != 1) {
    console.error(`OpenExchangeRates returned unexpected base currency`);
    return undefined;
  }
  delete json.rates.EUR;
  return {
    date: new Date(json.timestamp).toISOString(),
    eur: json.rates,
  };
}

async function fetchCurrencyData(): Promise<any> {
  let fawazData = (await fetchFawazCurrencyData())!;
  // check if fawazData is 5 or more days out of date
  if (
    fawazData == undefined ||
    Date.parse(fawazData.date) < Date.now() - 5 * 24 * 60 * 60 * 1000
  ) {
    console.error(`Fawaz data is out of date`);
    let openExchangeRatesData = await fetchOpenExchangeRatesData();
    if (openExchangeRatesData == undefined) {
      console.error(`Failed to fetch OpenExchangeRates data`);
      return undefined;
    }
    fawazData = openExchangeRatesData;
  }
  return fawazData;
}

export async function handleCron(event: any, env: Env) {
  const data = await fetchCurrencyData();
  if (data == undefined) {
    console.error(`Failed to fetch currency data`);
    return;
  }
  await env.KV.put("currencies", JSON.stringify(data));
}
