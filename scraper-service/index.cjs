const express = require("express");
const { chromium } = require("playwright");

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 3000;

/* =========================
   HEALTH CHECK
========================= */
app.get("/", (req, res) => {
  res.json({ status: "Scraper activo 🚀" });
});

/* =========================
   SHEIN SCRAPER
========================= */
app.post("/scrape/shein", async (req, res) => {
  const { url } = req.body;

  if (!url) {
    return res.status(400).json({ error: "URL requerida" });
  }

  let browser;

  try {
    browser = await chromium.launch({
      headless: true,
      args: [
        "--no-sandbox",
        "--disable-setuid-sandbox",
        "--disable-dev-shm-usage",
        "--disable-blink-features=AutomationControlled"
      ]
    });

    const context = await browser.newContext({
      userAgent:
        "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile Safari/604.1",
      viewport: { width: 390, height: 844 },
      locale: "es-CL"
    });

    // Evitar detección básica
    await context.addInitScript(() => {
      Object.defineProperty(navigator, "webdriver", {
        get: () => false
      });
    });

    const page = await context.newPage();

    await page.goto(url, {
      waitUntil: "domcontentloaded",
      timeout: 45000
    });

    // Esperar a que el título exista
    await page.waitForSelector("h1", { timeout: 20000 });

const data = await page.evaluate(() => {
  const clean = (text) =>
    text ? text.replace(/\s+/g, " ").trim() : null;

  let name = null;
  let price = null;
  let currency = null;
  let image = null;

  try {
    if (typeof window !== "undefined" && window.__INITIAL_STATE__) {
      const state = window.__INITIAL_STATE__;

      if (state && state.goodsDetail && state.goodsDetail.detail) {
        const product = state.goodsDetail.detail;

        name = product.goods_name || null;

        if (product.salePrice && product.salePrice.amount) {
          price = product.salePrice.amount;
          currency = product.salePrice.currency || "CLP";
        }

        image = product.goods_img || null;
      }
    }
  } catch (e) {
    console.log("STATE ERROR", e);
  }

  // Fallback DOM
  if (!name) {
    const h1 = document.querySelector("h1");
    if (h1) name = clean(h1.innerText);
  }

  if (!price) {
    const priceEl =
      document.querySelector('[data-testid="price"]') ||
      document.querySelector('[class*="price"]');
    if (priceEl) price = clean(priceEl.innerText);
  }

  if (!image) {
    const imgEl =
      document.querySelector('img[src*="shein"]');
    if (imgEl) image = imgEl.src;
  }

  return { name, price, currency, image };
});



    await browser.close();

    return res.json(data);

  } catch (error) {
    console.error("ERROR SHEIN:", error);

    if (browser) {
      await browser.close();
    }

    return res.status(500).json({
      error: "Error procesando Shein"
    });
  }
});

/* ========================= */

app.listen(PORT, () => {
  console.log(`Servidor corriendo en puerto ${PORT}`);
});
