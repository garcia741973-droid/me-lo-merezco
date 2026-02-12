const express = require("express");
const { chromium } = require("playwright");
const fs = require("fs");
const path = require("path");

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 3000;
const DEBUG_DIR = "/tmp";
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
        server: "http://v2.proxyempire.io:5000",
        username: "r_6c91ffefda-sid-g018fag0-country-cl",
        password: "e32819270d"
      },
      args: [
        "--no-sandbox",
        "--disable-setuid-sandbox",
        "--disable-dev-shm-usage",
        "--disable-blink-features=AutomationControlled",
      ],
    });

    const context = await browser.newContext({
      userAgent:
        "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile Safari/604.1",
      locale: "es-CL",
      timezoneId: "America/Santiago",
    });

    await context.addInitScript(() => {
      Object.defineProperty(navigator, "webdriver", {
        get: () => false,
      });
    });

    const page = await context.newPage();

    // 🔥 BLOQUEAR RECURSOS PESADOS (ahorra MB)
    await page.route("**/*", (route) => {
      const url = route.request().url();

      if (
        url.includes("googletag") ||
        url.includes("criteo") ||
        url.includes("pinterest") ||
        url.includes("analytics") ||
        url.endsWith(".jpg") ||
        url.endsWith(".png") ||
        url.endsWith(".webp")
      ) {
        return route.abort();
      }

      route.continue();
    });

    page.on("response", (response) => {
      if (response.request().resourceType() === "document") {
        console.log("NAV RESPONSE:", response.status(), response.url());
      }
    });

    let attempt = 0;

    while (attempt <= MAX_RETRIES) {
      try {
        console.log("Intento:", attempt + 1);

        const response = await page.goto(url, {
          waitUntil: "domcontentloaded",
          timeout: 30000,
        });

        if (!response) {
          throw new Error("No response");
        }

        console.log("HTTP Status:", response.status());

        try {
          await page.waitForLoadState("networkidle", { timeout: 10000 });
        } catch {}

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

        const now = Date.now();

        try {
          const screenshotPath = path.join(
            DEBUG_DIR,
            `shein_error_${now}.png`
          );
          const htmlPath = path.join(
            DEBUG_DIR,
            `shein_error_${now}.html`
          );

          await page.screenshot({
            path: screenshotPath,
            fullPage: true,
          });

          const html = await page.content();
          fs.writeFileSync(htmlPath, html);

          console.log("Debug guardado en:", screenshotPath);
          console.log("HTML guardado en:", htmlPath);
        } catch (debugErr) {
          console.error("Error guardando debug:", debugErr.message);
        }

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
