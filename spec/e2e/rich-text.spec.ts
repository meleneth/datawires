import { expect, test } from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';

test('formats, autosaves, reloads, and publishes a rich text JSON field', async ({ page }) => {
  const state = JSON.parse(fs.readFileSync(path.join(process.cwd(), 'tmp/playwright/builder_flow.json'), 'utf8'));
  const errors: string[] = [];
  page.on('pageerror', error => errors.push(error.message));
  await page.goto(state.richTextDraftPath);

  const editor = page.locator('lexxy-editor#field_bio');
  const content = editor.locator('[contenteditable="true"]');
  await expect(content.locator('em')).toHaveText('biography');
  await expect(editor.locator('input[type="file"]')).toHaveCount(0);

  // Merely loading the editor must not rewrite the stored document.
  let patches = 0;
  page.on('request', request => {
    if (request.url().includes('/patch_ptr')) patches += 1;
  });
  await page.waitForTimeout(600);
  expect(patches).toBe(0);

  const saved = page.waitForResponse(response => response.url().includes('/patch_ptr') && response.ok());
  await content.fill('Formatted biography');
  await content.press('ControlOrMeta+a');
  await content.press('ControlOrMeta+b');
  await saved;
  await expect(content.locator('strong')).toHaveText('Formatted biography');

  await page.reload();
  await expect(content.locator('strong')).toHaveText('Formatted biography');

  const cleared = page.waitForResponse(response => response.url().includes('/patch_ptr') && response.ok());
  await content.click();
  await content.press('ControlOrMeta+a');
  await content.press('Backspace');
  await cleared;
  await page.reload();
  await expect(content).toHaveText('');

  const resaved = page.waitForResponse(response => response.url().includes('/patch_ptr') && response.ok());
  await content.fill('Published biography');
  await content.press('ControlOrMeta+a');
  await content.press('ControlOrMeta+b');
  await resaved;
  await page.getByRole('link', { name: 'Commit', exact: true }).click();
  await page.getByLabel('Log message').fill('Publish formatted biography');
  await page.getByRole('button', { name: 'Commit draft', exact: true }).click();
  await expect(page.getByText('Draft committed.')).toBeVisible();
  await expect(page.locator('pre')).toContainText('<strong>Published biography</strong>');
  expect(errors).toEqual([]);
});
