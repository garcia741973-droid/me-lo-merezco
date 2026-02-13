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
      headless: false, // 🔥 IMPORTANTE: NO headless
      proxy: {
        server: "http://geo.iproyal.com:12321",
        username: "SA1UeEU0zGMrR7G9",
        password: "ZtkXm31fMmWVnBlM",
      },
      args: [
        "--disable-blink-features=AutomationControlled",
        "--no-sandbox",
        "--disable-setuid-sandbox",
      ],
    });
///
    const context = await browser.newContext({
      viewport: { width: 1366, height: 768 },
      userAgent:
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36",
      locale: "es-CL",
    });

    const page = await context.newPage();

    // 🔥 Ocultar webdriver
    await page.addInitScript(() => {
      Object.defineProperty(navigator, "webdriver", {
        get: () => undefined,
      });
    });

    await page.goto(url, {
      waitUntil: "networkidle",
      timeout: 60000,
    });

    // Simular comportamiento humano
    await page.waitForTimeout(4000);
    await page.mouse.move(200, 200);
    await page.waitForTimeout(2000);

    const finalUrl = page.url();

    console.log("FINAL URL:", finalUrl);

    if (finalUrl.includes("risk")) {
      throw new Error("Shein activó sistema anti-bot");
    }

    // 🔎 Extraer datos más específicos
    const title = await page
      .locator("h1")
      .first()
      .innerText()
      .catch(() => null);

    const price = await page
      .locator("[class*='price']")
      .first()
      .innerText()
      .catch(() => null);

    const image = await page
      .locator("img")
      .nth(1)
      .getAttribute("src")
      .catch(() => null);

    await browser.close();

    return res.json({
      success: true,
      title,
      price,
      image,
      finalUrl,
    });
  } catch (err) {
    console.log("ERROR:", err.message);

    if (browser) await browser.close();

    return res.status(500).json({
      success: false,
      error: err.message,
    });
  }
});

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Servidor corriendo en puerto ${PORT}`);
});
