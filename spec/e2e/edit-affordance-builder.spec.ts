import { expect, test } from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';

type BuilderFlowState = {
  builderPath: string;
};

const statePath = path.join(process.cwd(), 'tmp', 'playwright', 'builder_flow.json');

test('builds and refines a schema-backed edit affordance', async ({ page }) => {
  const state = JSON.parse(fs.readFileSync(statePath, 'utf8')) as BuilderFlowState;

  await page.goto(state.builderPath);

  await expect(page.getByRole('heading', { name: 'Edit affordance builder' })).toBeVisible();
  await expect(page.getByRole('heading', { name: 'Schema suggestions' })).toBeVisible();

  const requiredSuggestion = page
    .getByText('Add required fields')
    .locator('xpath=ancestor::div[contains(@class, "space-y-3")][1]');
  await requiredSuggestion.getByRole('button', { name: 'Apply' }).click();

  await page.getByRole('link', { name: 'Open field' }).click();

  const editor = page.locator('#edit_affordance_builder_editor');
  const fieldPath = editor.locator('select[name="ptr"]');
  const widget = editor.locator('select[name="widget"]');
  const span = editor.locator('input[name="span"]');
  const help = editor.locator('input[name="help"]');
  const placeholder = editor.locator('input[name="placeholder"]');
  await expect(editor.getByRole('heading', { name: 'Field 1' })).toBeVisible();
  await expect(fieldPath).toHaveValue('/name');
  await expect(page.locator('#edit_affordance_builder_rows').getByText('/name', { exact: true })).toBeVisible();

  await fieldPath.selectOption('/bio');
  await widget.selectOption('textarea');
  await span.fill('8');
  await help.fill('Revised help.');
  await placeholder.fill('Long form copy');
  await editor.getByLabel('Compact display').check();
  await editor.getByLabel('Read-only display').check();
  await editor.getByLabel('Show label').uncheck();
  await editor.getByRole('button', { name: 'Update field' }).click();

  await expect(editor.getByRole('heading', { name: 'Field 1' })).toBeVisible();
  await expect(fieldPath).toHaveValue('/bio');
  await expect(widget).toHaveValue('textarea');
  await expect(span).toHaveValue('8');
  await expect(help).toHaveValue('Revised help.');
  await expect(placeholder).toHaveValue('Long form copy');
  await expect(editor.getByLabel('Compact display')).toBeChecked();
  await expect(editor.getByLabel('Read-only display')).toBeChecked();
  await expect(editor.getByLabel('Show label')).not.toBeChecked();

  await page.reload();

  await expect(page.getByRole('heading', { name: 'Edit affordance builder' })).toBeVisible();
  await page.getByRole('link', { name: 'Open field' }).click();
  await expect(editor.getByRole('heading', { name: 'Field 1' })).toBeVisible();
  await expect(fieldPath).toHaveValue('/bio');
  await expect(widget).toHaveValue('textarea');
  await expect(span).toHaveValue('8');
  await expect(help).toHaveValue('Revised help.');
  await expect(placeholder).toHaveValue('Long form copy');
  await expect(editor.getByLabel('Compact display')).toBeChecked();
  await expect(editor.getByLabel('Read-only display')).toBeChecked();
});
