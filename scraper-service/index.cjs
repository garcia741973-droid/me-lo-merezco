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

  const context = await browser.newContext({
  userAgent:
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
});
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

    await page.waitForLoadState('domcontentloaded');
    await page.waitForTimeout(5000);


const data = await page.evaluate(() => {
  const result = {
    name: null,
    price: null,
    currency: null,
    image: null
  };

  // Intentar encontrar JSON interno
  const scripts = Array.from(document.querySelectorAll('script'));

  for (const script of scripts) {
    if (script.innerText.includes('window.gbCommonInfo')) {
      try {
        const match = script.innerText.match(/window\.gbCommonInfo\s*=\s*(\{.*?\});/s);
        if (match) {
          const json = JSON.parse(match[1]);

          result.currency = json?.currency?.currencyCode || null;
        }
      } catch (e) {}
    }

    if (script.innerText.includes('__INITIAL_STATE__')) {
      try {
        const match = script.innerText.match(/__INITIAL_STATE__\s*=\s*(\{.*?\});/s);
        if (match) {
          const json = JSON.parse(match[1]);

          const product = json?.goodsDetail?.goodsInfo;

          result.name = product?.goodsName || null;
          result.price = product?.retailPrice?.amount || null;
          result.image = product?.goodsImage || null;
        }
      } catch (e) {}
    }
  }

  return result;
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
