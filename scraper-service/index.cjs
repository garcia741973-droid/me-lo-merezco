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
      headless: false,
      proxy: {
        server: "geo.iproyal.com:12321",
        username: "SA1UeEU0zGMrR7G9",
        password: "ZtkXm31fMmWVnBlM_country-cl",
      },
    });

    const context = await browser.newContext({
      userAgent:
        "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1",
      locale: "es-CL",
    });

    const page = await context.newPage();

    // 🔎 Ver IP real desde navegador
    await page.goto("https://api.myip.com", { waitUntil: "domcontentloaded" });
    const ipCheck = await page.textContent("body");
    console.log("IP ACTUAL VIA BROWSER:", ipCheck);

    // Ir al producto
    await page.goto(url, {
      waitUntil: "domcontentloaded",
      timeout: 60000,
    });

const currentHtml = await page.content();
console.log("PAGE URL:", page.url());
console.log("PAGE LENGTH:", currentHtml.length);

if (currentHtml.includes("captcha") || currentHtml.includes("verify")) {
  console.log("⚠️ POSIBLE BLOQUEO DETECTADO");
}


    await page.waitForSelector("h1", { timeout: 20000 });

    const titleLocator = page.locator("h1").first();
    const title = (await titleLocator.count()) > 0
      ? await titleLocator.innerText()
      : null;

    // Precio seguro
    let price = null;
    const priceLocator = page.locator("[class*='price'], [class*='Price']").first();

    if (await priceLocator.count() > 0) {
      price = await priceLocator.innerText();
    }

    console.log("PRECIO RAW:", price);

    // Imagen segura
    let image = null;
    const imageLocator = page.locator("img[src*='img.ltwebstatic']").first();

    if (await imageLocator.count() > 0) {
      image = await imageLocator.getAttribute("src");
    }

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
