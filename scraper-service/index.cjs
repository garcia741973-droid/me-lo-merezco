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
      proxy: {
        server: "http://geo.iproyal.com:12321",
        username: "SA1UeEU0zGMrR7G9",
        password: "ZtkXm31fMmWVnBlM",
      },
    });

    const context = await browser.newContext({
      userAgent:
        "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1",
      locale: "es-CL",
    });

    const page = await context.newPage();

    await page.goto(url, {
      waitUntil: "domcontentloaded",
      timeout: 60000,
    });

    await page.waitForTimeout(5000);

    const finalUrl = page.url();

    if (finalUrl.includes("risk")) {
      throw new Error("Shein redirigió a página de riesgo");
    }

    const title = await page.title();

    const price = await page
      .locator("[class*='price']")
      .first()
      .innerText()
      .catch(() => null);

    const image = await page
      .locator("img")
      .first()
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
