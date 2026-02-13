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

  if (!url) {
    return res.status(400).json({ error: "URL requerida" });
  }

  let browser;

  try {
    browser = await chromium.launch({
      headless: true,
      proxy: {
        server: "http://v2.proxyempire.io:5000",
        username: "r_6c91ffefda-country-cl-sid-k6ba3b6j",
        password: "e32819270d"
      }
    });

    const context = await browser.newContext({
      locale: "es-CL",
      timezoneId: "America/Santiago",
      userAgent:
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    });

    const page = await context.newPage();

    const response = await page.goto(url, {
      waitUntil: "domcontentloaded",
      timeout: 30000
    });

    await page.waitForTimeout(6000);

    const html = await page.content();
    console.log("HTML LENGTH:", html.length);
    console.log("FINAL URL:", page.url());

    const title = await page.title();

    await browser.close();

    return res.json({
      success: true,
      title,
      finalUrl: page.url()
    });

  } catch (error) {
    console.error("ERROR:", error.message);
    if (browser) await browser.close();
    return res.status(500).json({ success: false, error: error.message });
  }
});


app.listen(PORT, "0.0.0.0", () => {
  console.log(`Servidor corriendo en puerto ${PORT}`);
});
