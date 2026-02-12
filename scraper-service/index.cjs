const express = require('express');
const { chromium } = require('playwright');

const app = express();
app.use(express.json());

app.post('/scrape/shein', async (req, res) => {
  try {
    const { url } = req.body;

    if (!url || !url.includes('shein.com')) {
      return res.status(400).json({ error: 'URL inválida' });
    }

    const browser = await chromium.launch({
      headless: true,
      args: [
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--disable-dev-shm-usage'
      ]
    });

    const page = await browser.newPage();

    await page.goto(url, {
      waitUntil: 'networkidle',
      timeout: 60000
    });

    const data = await page.evaluate(() => {
      const clean = (t) =>
        parseFloat(t?.replace(/[^0-9.]/g, ''));

      const name =
        document.querySelector('h1')?.innerText || '';

      const priceEl =
        document.querySelector('[class*="price"]');

      const price = clean(priceEl?.innerText);

      const image =
        document.querySelector('img')?.src || '';

      return { name, price, image };
    });

    await browser.close();

    res.json(data);

  } catch (err) {
    console.error('SCRAPER ERROR:', err);
    res.status(500).json({ error: 'Scraper failed' });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log('Scraper running on port', PORT);
});
