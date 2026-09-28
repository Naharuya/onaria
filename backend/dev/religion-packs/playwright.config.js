import { defineConfig } from '@playwright/test';
export default defineConfig({
  testDir: './e2e', testMatch: '*.spec.js', workers: 1,
  reporter: [['list']], outputDir: '../../../build/buddhist-e2e',
  use: { browserName: 'chromium', screenshot: 'only-on-failure', trace: 'retain-on-failure' },
});
