import { expect, test } from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';

type WorkspaceState = { domainPath: string; boardPath: string };
const statePath = path.join(process.cwd(), 'tmp', 'playwright', 'project_workspace.json');

test('authors project definitions and presents observation graphs', async ({ page }) => {
  const state = JSON.parse(fs.readFileSync(statePath, 'utf8')) as WorkspaceState;
  await page.goto(state.domainPath);
  await expect(page.getByRole('heading', { name: 'Signals Workspace' })).toBeVisible();

  await page.getByRole('link', { name: 'Credentials' }).click();
  await page.getByRole('link', { name: 'New credential' }).click();
  await page.getByLabel('Name').fill('browser-api');
  await page.getByLabel('Authorization value').fill('Bearer browser-secret');
  await page.getByRole('button', { name: 'Create credential' }).click();
  await expect(page.getByText('browser-api')).toBeVisible();
  await expect(page.getByText('Bearer browser-secret')).not.toBeVisible();

  await page.goto(state.domainPath);
  await page.getByRole('link', { name: 'Metrics' }).click();
  await page.getByRole('link', { name: 'New metric' }).click();
  await page.getByLabel('Key').fill('temperature');
  await page.getByLabel('Title').fill('Temperature');
  await page.getByLabel('Unit').fill('C');
  await page.getByRole('button', { name: 'Create metric' }).click();
  await expect(page.getByRole('heading', { name: 'Temperature' })).toBeVisible();

  await page.goto(state.boardPath);
  await expect(page.getByRole('heading', { name: 'Operations' })).toBeVisible();
  await expect(page.getByText('Temperature')).toBeVisible();
  await expect(page.locator('[data-controller="series-chart"] svg')).toBeVisible();
});

test('exports both full and configuration-only project archives', async ({ page }) => {
  const state = JSON.parse(fs.readFileSync(statePath, 'utf8')) as WorkspaceState;
  await page.goto(state.domainPath);

  const fullDownload = page.waitForEvent('download');
  await page.getByRole('link', { name: 'Export full archive' }).click();
  expect((await fullDownload).suggestedFilename()).toMatch(/archive\.json$/);

  await page.goto(state.domainPath);
  const configDownload = page.waitForEvent('download');
  await page.getByRole('link', { name: 'Export configuration only' }).click();
  expect((await configDownload).suggestedFilename()).toMatch(/archive\.json$/);
});
