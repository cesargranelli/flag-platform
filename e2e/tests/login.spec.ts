import { expect, test } from '@playwright/test';

import { enableFlutterSemantics, flutterField } from '../support/flutter';

const ORGANIZER_EMAIL = process.env.E2E_ORGANIZER_EMAIL || 'organizer@flag.test';
const ORGANIZER_PASSWORD =
  process.env.E2E_ORGANIZER_PASSWORD || 'Organizer@123';

/**
 * Fluxo de autenticação do Admin Web (Flutter Web).
 *
 * Rota inicial `/` redireciona para `/login` quando não autenticado.
 * Após login com credenciais válidas o GoRouter redireciona para `/` (home);
 * com credenciais inválidas o backend retorna 401 e o app exibe
 * "Email or password is invalid." (campo `message` do corpo da resposta).
 */
test.describe('Login', () => {
  test('login válido autentica e redireciona para a home', async ({
    page,
  }) => {
    await page.goto('/');
    await enableFlutterSemantics(page);

    await flutterField(page, 'E-mail').click();
    await page.keyboard.type(ORGANIZER_EMAIL);

    await flutterField(page, 'Senha').click();
    await page.keyboard.type(ORGANIZER_PASSWORD);

    await page.getByRole('button', { name: 'Entrar' }).click();

    // Home (rota "/"): header de boas-vindas + card de acesso "Organizações".
    await expect(page).toHaveURL(/\/$/, { timeout: 20_000 });
    await expect(page.getByText('Organizações')).toBeVisible({
      timeout: 20_000,
    });
  });

  test('login com credenciais inválidas exibe mensagem de erro', async ({
    page,
  }) => {
    await page.goto('/');
    await enableFlutterSemantics(page);

    await flutterField(page, 'E-mail').click();
    await page.keyboard.type('nao-existe@flag.test');

    await flutterField(page, 'Senha').click();
    await page.keyboard.type('SenhaErrada@123');

    await page.getByRole('button', { name: 'Entrar' }).click();

    // Mensagem do backend (HTTP 401) exposta na tela de login.
    await expect(page.getByText('Email or password is invalid.')).toBeVisible(
      { timeout: 15_000 },
    );

    // Continua na tela de login (sem redirecionamento).
    await expect(page).toHaveURL(/\/login/);
  });
});
