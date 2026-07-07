import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './spec/e2e',
  globalSetup: './spec/e2e/global-setup.ts',
  timeout: 60_000,
  expect: {
    timeout: 5_000
  },
  use: {
    baseURL: 'http://127.0.0.1:31337',
    trace: 'on-first-retry'
  },
  reporter: [['list'], ['html', { open: 'never' }]],
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] }
    }
  ]
});
