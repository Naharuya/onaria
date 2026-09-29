import { defineConfig, devices } from '@playwright/test';
export default defineConfig({
  testDir: './webapp-e2e', workers: 1, timeout: 90_000,
  reporter: [['list']], outputDir: '../build/webapp-test-results',
  use: { baseURL: 'http://127.0.0.1:8788', actionTimeout: 15000, screenshot: 'only-on-failure', trace: 'retain-on-failure' },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'webkit-small-screen', use: { browserName: 'webkit', viewport: { width: 390, height: 844 }, deviceScaleFactor: 3 } },
  ],
  webServer: { command: 'node ../scripts/serve-webapp.mjs ../build/web', url: 'http://127.0.0.1:8788/webapp/', reuseExistingServer: false },
});
