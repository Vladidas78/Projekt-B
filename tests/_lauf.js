// Gemeinsame Hilfen für die Browser-Tests (Playwright, Chromium aus PLAYWRIGHT_BROWSERS_PATH).
// Aufruf je Test: node tests/<datei>.js [Pfad zur HTML-Datei]; ohne Pfad wird SupportBoard_Test.html geprüft.
const { chromium } = require('playwright');
const path = require('path'), os = require('os');
let fails = 0;
function check(name, cond, info) { console.log((cond ? 'OK   ' : 'FAIL ') + name + (cond ? '' : '  -> ' + info)); if (!cond) fails++; }
async function start() {
  const html = process.argv[2] || path.resolve(__dirname, '..', 'SupportBoard_Test.html');
  const browser = await chromium.launch({ args: ['--no-sandbox'], ...(process.env.PW_CHROME ? { executablePath: process.env.PW_CHROME } : {}) });
  const page = await browser.newPage({ viewport: { width: 1600, height: 1100 } });
  const errors = [];
  page.on('pageerror', e => errors.push(String(e)));
  page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
  page.on('dialog', d => d.accept());
  await page.goto('file://' + html);
  return { browser, page, errors };
}
async function anmelden(page) { const b = await page.$('#loginList button:nth-child(1)'); if (b) await b.click(); await page.waitForTimeout(200); }
async function ende(browser, errors) {
  check('Keine Seitenfehler', errors.length === 0, errors.join(' | '));
  await browser.close();
  console.log(fails ? `\n${fails} FEHLER` : '\nALLE TESTS OK');
  process.exitCode = fails ? 1 : 0;
}
const bildPfad = name => path.join(process.env.SHOT_DIR || os.tmpdir(), name);
module.exports = { check, start, anmelden, ende, bildPfad };
