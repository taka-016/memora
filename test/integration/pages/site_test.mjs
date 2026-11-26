import assert from 'node:assert/strict';
import { after, before, test } from 'node:test';
import { chromium } from 'playwright';

let browser;
before(async () => { browser = await chromium.launch(); });
after(async () => { await browser?.close(); });
const site = new URL('../../../docs/', import.meta.url);
const files = ['index.html', 'privacy.html', 'terms.html'];

for (const file of files) {
  test(`${file}: 小さい画面と文字拡大時にも横スクロールせず読める`, async () => {
    const page = await browser.newPage();
    try {
      await page.goto(new URL(file, site).href);
      for (const width of [320, 375, 768, 1280]) {
        await page.setViewportSize({ width, height: 900 });
        for (const fontSize of ['100%', '200%']) {
          await page.evaluate(size => { document.documentElement.style.fontSize = size; }, fontSize);
          assert.ok(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), `${width}px / ${fontSize}`);
        }
      }
    } finally { await page.close(); }
  });

  test(`${file}: キーボードで本文へ移動できフォーカスを識別できる`, async () => {
    const page = await browser.newPage();
    try {
      await page.goto(new URL(file, site).href);
      await page.keyboard.press('Tab');
      const focus = await page.evaluate(() => {
        const element = document.activeElement;
        const style = getComputedStyle(element);
        return { href: element.getAttribute('href'), top: element.getBoundingClientRect().top, outline: style.outlineColor, shadow: style.boxShadow };
      });
      assert.equal(focus.href, '#main');
      assert.ok(focus.top >= 0);
      assert.equal(focus.outline, 'rgb(0, 0, 0)');
      assert.ok(focus.shadow.includes('rgb(255, 232, 0)'));
      await page.keyboard.press('Enter');
      assert.equal(new URL(page.url()).hash, '#main');
      const tooSmall = await page.locator('main p, main a, header nav a').evaluateAll(elements => elements.filter(element => parseFloat(getComputedStyle(element).fontSize) < 16).map(element => element.textContent));
      assert.deepEqual(tooSmall, []);
    } finally { await page.close(); }
  });
}

for (const file of ['privacy.html', 'terms.html']) {
  test(`${file}: 目次からすべての節へ移動できる`, async () => {
    const page = await browser.newPage();
    try {
      await page.goto(new URL(file, site).href);
      const sections = await page.locator('.document section').count();
      const links = page.getByRole('navigation', { name: 'このページの目次' }).getByRole('link');
      assert.equal(await links.count(), sections);
      for (const link of await links.all()) {
        const target = await link.getAttribute('href');
        await link.click();
        assert.equal(new URL(page.url()).hash, target);
        assert.equal(await page.locator(target).count(), 1);
      }
      await page.getByRole('navigation', { name: 'メインナビゲーション' }).getByRole('link', { name: 'ホーム', exact: true }).click();
      assert.ok(page.url().endsWith('/index.html'));
    } finally { await page.close(); }
  });
}
