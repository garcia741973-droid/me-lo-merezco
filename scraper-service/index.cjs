const express = require("express");
const { chromium } = require("playwright");

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 3000;

// ===============================
// HEALTH CHECK
// ===============================
app.get("/", (req, res) => {
  res.json({ status: "Scraper activo 🚀" });
});

// ===============================
// ENDPOINT PROXY TEST
// ===============================
app.post("/scrape/shein", async (req, res) => {
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

    const page = await browser.newPage();

    await page.goto("https://ipinfo.io/json", {
      waitUntil: "domcontentloaded",
      timeout: 30000
    });

    await page.waitForTimeout(3000);

    const content = await page.content();

    console.log("IP TEST RESULT:");
    console.log(content);

    await browser.close();

    return res.json({ success: true });

  } catch (error) {
    console.error("ERROR:", error.message);

    if (browser) await browser.close();

    return res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ===============================
// START SERVER
// ===============================
app.listen(PORT, "0.0.0.0", () => {
  console.log(`Servidor corriendo en puerto ${PORT}`);
});
