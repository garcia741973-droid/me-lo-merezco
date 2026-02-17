const { chromium } = require("playwright");

(async () => {
  const browser = await chromium.launch({
    headless: true,
    proxy: {
      server: "http://geo.iproyal.com:12321",
      username: "SA1UeEU0zGMrR7G9",
      password: "ZtkXm31fMmWVnBlM"
    }
  });

  const page = await browser.newPage();

  await page.goto("https://m.shein.com/cl/Manfinity-Dauomo-Men-s-Letter-Textured-Slim-Fit-Round-Neck-Tank-Top-p-62707258.html", {
    waitUntil: "domcontentloaded",
    timeout: 60000
  });

  await page.waitForTimeout(8000);

  const title = await page.title();
  console.log("TITLE:", title);

  await browser.close();
})();

