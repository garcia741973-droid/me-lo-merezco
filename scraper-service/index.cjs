const express = require('express');
const { chromium } = require('playwright');

const app = express();
app.use(express.json());

app.post('/scrape/shein', async (req, res) => {
  let browser;

  try {
    const { url } = req.body;

    if (!url || !url.includes('shein.com')) {
      return res.status(400).json({ error: 'URL inválida' });
    }

    // Lanzar Chromium en modo ultra liviano para Railway
    browser = await chromium.launch({
      headless: true,
      args: [
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--disable-dev-shm-usage',
        '--disable-gpu',
        '--single-process',
        '--no-zygote',
        '--no-first-run',
        '--no-default-browser-check'
      ]
    });

    const context = await browser.newContext();
    const page = await context.newPage();

    // Bloquear recursos pesados
    await page.route('**/*', route => {
      const resourceType = route.request().resourceType();
      if (
        resourceType === 'image' ||
        resourceType === 'media' ||
        resourceType === 'font'
      ) {
        route.abort();
      } else {
        route.continue();
      }
    });

    await page.goto(url, {
      waitUntil: 'domcontentloaded',
      timeout: 30000
    });

    await page.waitForSelector('h1', { timeout: 15000 });

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

    res.json(data);

  } catch (err) {
    console.error('SCRAPER ERROR:', err);
    res.status(500).json({ error: 'Scraper failed' });

  } finally {
    if (browser) {
      try {
        await browser.close();
      } catch (e) {
        console.error('Error closing browser:', e);
      }
    }
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log('Scraper running on port', PORT);
});
