const express = require("express");
const { chromium } = require("playwright");

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 3000;

app.get("/", (req, res) => {
  res.json({ status: "Scraper activo 🚀" });
});

app.post("/scrape/shein", async (req, res) => {
  const { url } = req.body;
  if (!url) return res.status(400).json({ error: "URL requerida" });

  let browser;

  try {
    browser = await chromium.launch({
      headless: true,
      args: [
        "--no-sandbox",
        "--disable-dev-shm-usage"
      ],
      proxy: {
        server: "geo.iproyal.com:12321",
        username: "SA1UeEU0zGMrR7G9", // PROXY RANDOM
        password: "ZtkXm31fMmWVnBlM", // SIN country targeting
      },
    });

    const context = await browser.newContext({
      userAgent:
        "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1",
      locale: "es-CL",
    });

    const page = await context.newPage();

    // 🔎 Ver IP real
    await page.goto("https://api.myip.com", { waitUntil: "domcontentloaded" });
    const ipCheck = await page.textContent("body");
    console.log("IP ACTUAL VIA BROWSER:", ipCheck);

    // Ir al producto
    await page.goto(url, {
      waitUntil: "domcontentloaded",
      timeout: 60000,
    });

    const finalUrl = page.url();
    console.log("FINAL URL:", finalUrl);

    if (finalUrl.includes("risk")) {
      throw new Error("Shein redirigió a página de riesgo");
    }

    // Esperar título visible
    await page.waitForSelector("h1", { timeout: 20000 });

    // ======================
    // EXTRAER DATOS
    // ======================

    // Título
    let title = null;
    const titleLocator = page.locator("h1").first();

    if (await titleLocator.count() > 0) {
      title = await titleLocator.innerText();
    }

    // Precio estructurado
    let priceRaw = null;
    let priceValue = null;
    let currency = null;

    const priceLocator = page
      .locator("[class*='price'], [class*='Price']")
      .first();

    if (await priceLocator.count() > 0) {
      priceRaw = await priceLocator.innerText();

      const numeric = priceRaw.replace(/[^\d]/g, "");
      priceValue = numeric ? parseInt(numeric, 10) : null;
    }

    // Detectar moneda por región URL
    if (url.includes("/cl/")) {
      currency = "CLP";
    } else if (url.includes("/mx/")) {
      currency = "MXN";
    } else if (url.includes("/es/")) {
      currency = "EUR";
    } else {
      currency = "USD";
    }

    console.log("TITLE:", title);
    console.log("PRICE RAW:", priceRaw);
    console.log("PRICE VALUE:", priceValue);
    console.log("CURRENCY:", currency);

    // Imagen
    let image = null;
    const imageLocator = page
      .locator("img[src*='img.ltwebstatic']")
      .first();

    if (await imageLocator.count() > 0) {
      image = await imageLocator.getAttribute("src");
    }

    await browser.close();

    return res.json({
      success: true,
      title,
      priceRaw,
      priceValue,
      currency,
      image,
      finalUrl,
    });

  } catch (err) {
    if (browser) await browser.close();

    console.error("ERROR:", err.message);

    return res.status(500).json({
      success: false,
      error: err.message,
    });
  }
});

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Servidor corriendo en puerto ${PORT}`);
});
