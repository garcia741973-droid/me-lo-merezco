const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const DEBUG_DIR = '/tmp';

// ===============================
// CONFIG
// ===============================
const MAX_RETRIES = 2;
const TIMEOUT = 20000;

async function delay(ms) {
  return new Promise(res => setTimeout(res, ms));
}

// ===============================
// FUNCION ROBUSTA PARA OBTENER TITULO
// ===============================
async function robustExtractTitle(page) {

  const selectors = [
    'h1',
    'header h1',
    '.product-intro__head-name',
    '.product-title',
    'meta[property="og:title"]',
    'title'
  ];

  for (const sel of selectors) {
    try {

      if (sel === 'title') {
        const title = await page.title();
        if (title) return { selector: 'title', text: title };
      }

      if (sel.startsWith('meta')) {
        const meta = await page.$(sel);
        if (meta) {
          const content = await meta.getAttribute('content');
          if (content) return { selector: sel, text: content };
        }
      }

      const el = await page.$(sel);
      if (el) {
        await page.waitForSelector(sel, { visible: true, timeout: 2000 });
        const text = await el.innerText();
        if (text && text.trim().length > 3) {
          return { selector: sel, text: text.trim() };
        }
      }

    } catch (err) {
      // seguimos probando otros selectores
    }
  }

  return null;
}

// ===============================
// SCRAPER PRINCIPAL
// ===============================
async function scrape(url) {

  console.log('====================================');
  console.log('SCRAPER START:', new Date().toISOString());
  console.log('URL:', url);

  const browser = await chromium.launch({
    headless: true, // cambiar a false para debug visual
  });

  const context = await browser.newContext({
    userAgent:
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36',
    locale: 'es-ES',
  });

  const page = await context.newPage();

  // Mitigación básica headless detection
  await page.addInitScript(() => {
    Object.defineProperty(navigator, 'webdriver', {
      get: () => false,
    });
  });

  // Log de responses importantes
  page.on('response', (response) => {
    if (response.request().resourceType() === 'document') {
      console.log('NAV RESPONSE:', response.status(), response.url());
    }
  });

  let attempt = 0;

  while (attempt <= MAX_RETRIES) {
    try {

      console.log(`Intento ${attempt + 1}`);

      const response = await page.goto(url, {
        waitUntil: 'domcontentloaded',
        timeout: 30000,
      });

      if (!response) {
        throw new Error('No response received');
      }

      console.log('Goto status:', response.status());

      // Esperamos red ociosa
      try {
        await page.waitForLoadState('networkidle', { timeout: 10000 });
      } catch (err) {
        console.log('networkidle no alcanzado, continuando...');
      }

      // Intentar extraer título
      const result = await robustExtractTitle(page);

      if (!result) {
        throw new Error('No se encontró ningún selector válido para título');
      }

      console.log('Selector usado:', result.selector);
      console.log('Texto:', result.text);

      await browser.close();

      return {
        success: true,
        title: result.text,
      };

    } catch (err) {

      console.error('ERROR SHEIN:', err.message);

      const now = Date.now();

      try {
        const screenshotPath = path.join(DEBUG_DIR, `scraper_error_${now}.png`);
        const htmlPath = path.join(DEBUG_DIR, `scraper_error_${now}.html`);

        await page.screenshot({ path: screenshotPath, fullPage: true });
        const html = await page.content();
        fs.writeFileSync(htmlPath, html);

        console.log('Debug guardado en:', screenshotPath);
        console.log('HTML guardado en:', htmlPath);

      } catch (debugErr) {
        console.error('Error guardando debug:', debugErr.message);
      }

      if (attempt < MAX_RETRIES) {
        attempt++;
        console.log('Reintentando en 3 segundos...');
        await delay(3000);
        continue;
      }

      await browser.close();

      return {
        success: false,
        error: err.message,
      };
    }
  }
}

// ===============================
// EXPORT PARA USO EN EXPRESS
// ===============================
module.exports = { scrape };


