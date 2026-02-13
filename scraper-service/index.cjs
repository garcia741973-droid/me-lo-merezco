const express = require("express");
const { chromium } = require("playwright");

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 3000;
const MAX_RETRIES = 2;

// ===============================
// FUNCIÓN ROBUSTA PARA EXTRAER TÍTULO
// ===============================
async function robustExtractTitle(page) {
  const selectors = [
    "h1",
    "header h1",
    ".product-intro__head-name",
    ".product-title",
    "meta[property='og:title']",
    "title",
  ];

  for (const sel of selectors) {
    try {
      if (sel === "title") {
        const title = await page.title();
        if (title) return title;
      }

      if (sel.startsWith("meta")) {
        const meta = await page.$(sel);
        if (meta) {
          const content = await meta.getAttribute("content");
          if (content) return content;
        }
      }

      const el = await page.$(sel);
      if (el) {
        const text = await el.innerText();
        if (text && text.trim().length > 3) {
          return text.trim();
        }
      }
    } catch (e) {}
  }

  return null;
}

// ===============================
// HEALTH CHECK
// ===============================
app.get("/", (req, res) => {
  res.json({ status: "Scraper activo 🚀" });
});

// ===============================
// ENDPOINT SHEIN
// ===============================
app.post("/scrape/shein", async (req, res) => {
  const { url } = req.body;

  if (!url) {
    return res.status(400).json({ error: "URL requerida" });
  }

  let browser;

  try {
browser = await chromium.launch({
  headless: true,
  proxy: {
    server: ""http://v2.proxyempire.io:5000",
    username: "r_6c91ffefda-country-cl-sid-k6ba3b6j",
    password: "e32819270d"
  },
 // args: [
 //   "--no-sandbox",
 //   "--disable-setuid-sandbox",
 //   "--disable-dev-shm-usage",
 // ],
});

const page = await browser.newPage();

await page.goto("https://ipinfo.io/json");
await page.waitForTimeout(3000);

const content = await page.content();
console.log(content);

await browser.close();

return res.json({ ok: true });

    const context = await browser.newContext({
      locale: "es-CL",
      timezoneId: "America/Santiago",
      userAgent:
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    });

    await context.addInitScript(() => {
      Object.defineProperty(navigator, "webdriver", {
        get: () => false,
      });
    });

    const page = await context.newPage();

    page.on("response", (response) => {
      if (response.request().resourceType() === "document") {
        console.log("NAV RESPONSE:", response.status(), response.url());
      }
    });

    let attempt = 0;

    while (attempt <= MAX_RETRIES) {
      try {
        console.log("Intento:", attempt + 1);

const response = await page.goto("https://ipinfo.io/json", {
  waitUntil: "domcontentloaded",
  timeout: 30000,
});

await page.waitForTimeout(3000);

const ipData = await page.content();
console.log("IP TEST RESPONSE:");
console.log(ipData);

return res.json({
  success: true,
  ipData
});


        if (!response) {
          throw new Error("No response");
        }

        console.log("HTTP Status:", response.status());

        // ⬇️ Espera simple para SPA (reemplaza networkidle)
        await page.waitForTimeout(6000);
        const html = await page.content();
        console.log("HTML LENGTH:", html.length);
        console.log("URL FINAL:", page.url());

        const title = await robustExtractTitle(page);

        if (!title) {
          throw new Error("No se encontró título");
        }

        await browser.close();

        return res.json({
          success: true,
          title,
        });

      } catch (err) {
        console.error("ERROR SHEIN:", err.message);

        if (attempt < MAX_RETRIES) {
          attempt++;
          await new Promise((r) => setTimeout(r, 3000));
          continue;
        }

        await browser.close();

        return res.status(500).json({
          success: false,
          error: err.message,
        });
      }
    }

  } catch (error) {
    console.error("FATAL ERROR:", error.message);

    if (browser) await browser.close();

    return res.status(500).json({
      success: false,
      error: "Error interno del scraper",
    });
  }
});

// ===============================
// START SERVER
// ===============================
app.listen(PORT, "0.0.0.0", () => {
  console.log(`Servidor corriendo en puerto ${PORT}`);
});
