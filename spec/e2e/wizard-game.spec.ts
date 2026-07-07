import { expect, test } from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';
import type { Page } from '@playwright/test';

type WizardGameState = {
  startPath: string;
  safeChoices: string[];
};

const statePath = path.join(process.cwd(), 'tmp', 'playwright', 'wizard_game.json');

async function clickChoice(page: Page, label: string, action: 'Enter' | 'Choose') {
  const choice = page.getByText(label).locator('xpath=ancestor::div[contains(@class, "space-y-3")][1]');
  await choice.getByRole('link', { name: action }).click();
}

test('plays the Wizard World safe path', async ({ page }) => {
  const state = JSON.parse(fs.readFileSync(statePath, 'utf8')) as WizardGameState;

  await page.goto(state.startPath);

  await expect(page.getByRole('heading', { name: 'Choice Play' })).toBeVisible();
  await expect(page.getByRole('heading', { name: "Wizard's Gate" })).toBeVisible();
  await expect(page.getByText('Room 1')).toBeVisible();
  await expect(page.getByText('Touch the thorn rune')).toBeVisible();
  await expect(page.getByText('Touch the moon rune')).toBeVisible();
  await expect(page.getByText('Touch the ash rune')).toBeVisible();

  await clickChoice(page, state.safeChoices[0], 'Enter');
  await expect(page.getByRole('heading', { name: 'Mirror Hall' })).toBeVisible();
  await expect(page.getByText('Room 2')).toBeVisible();
  await expect(page.getByText('Step into the listening mirror')).toBeVisible();

  await clickChoice(page, state.safeChoices[1], 'Enter');
  await expect(page.getByRole('heading', { name: 'Star Vault' })).toBeVisible();
  await expect(page.getByText('Room 3')).toBeVisible();
  await expect(page.getByText('Claim the white star')).toBeVisible();

  await clickChoice(page, state.safeChoices[2], 'Choose');
  await expect(page.getByRole('heading', { name: "Wizard's World Won" })).toBeVisible();
  await expect(page.getByText('The vault opens, the gate remembers your name, and the wizard lets you pass.').first()).toBeVisible();
  await expect(page.getByRole('link', { name: /Enter|Choose/ })).toHaveCount(0);
});
