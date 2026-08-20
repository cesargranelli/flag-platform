import { defineConfig, devices } from '@playwright/test';

/**
 * Configuração da suíte E2E do Flag Platform (issue #202).
 *
 * Alvos: build web do Admin Web (Flutter Web) em `BASE_URL` (default
 * http://localhost:8081) + backend efêmero em http://localhost:8080.
 *
 * Variáveis de ambiente:
 *   BASE_URL            URL da aplicação web em teste (default http://localhost:8081)
 *   E2E_RETRIES         retries por teste (default 1)
 *   E2E_WORKERS         workers paralelos (default 1; CI usa shards via CLI)
 *   E2E_ORGANIZER_EMAIL e-mail do organizador do seed de staging
 *   E2E_ORGANIZER_PASSWORD senha do organizador do seed de staging
 */

const baseURL = process.env.BASE_URL || 'http://localhost:8081';
const retries =
  process.env.E2E_RETRIES !== undefined
    ? Number(process.env.E2E_RETRIES)
    : 1;
const workers =
  process.env.E2E_WORKERS !== undefined
    ? Number(process.env.E2E_WORKERS)
    : 1;

export default defineConfig({
  testDir: './tests',
  outputDir: 'test-results',
  timeout: 60_000,
  expect: {
    timeout: 15_000,
  },
  fullyParallel: false,
  retries,
  workers,
  reporter: [
    ['html', { outputFolder: 'playwright-report', open: 'never' }],
  ],
  use: {
    baseURL,
    trace: 'retain-on-failure',
    screenshot: 'retain-on-failure',
    video: 'retain-on-failure',
    actionTimeout: 15_000,
    navigationTimeout: 30_000,
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
});
