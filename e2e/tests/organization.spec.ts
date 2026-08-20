import { expect, test } from '@playwright/test';

import { gerarCpfValido } from '../support/cpf';
import { enableFlutterSemantics, flutterFill } from '../support/flutter';

const ORGANIZER_EMAIL = process.env.E2E_ORGANIZER_EMAIL || 'organizer@flag.test';
const ORGANIZER_PASSWORD =
  process.env.E2E_ORGANIZER_PASSWORD || 'Organizer@123';

/**
 * Criação de organização via wizard (5 etapas) no Admin Web (Flutter Web).
 *
 * Etapas do form (labels reais do `organization_form_screen.dart`):
 *   1. Identificação — "Nome fantasia" e "Razão social" (obrigatórios)
 *   2. Presidente — "Nome do presidente" e "CPF do presidente" (obrigatórios)
 *   3. Contato — opcionais
 *   4. Localização — opcionais
 *   5. Identidade — opcionais
 * Botões: "Continuar"/"Voltar" no meio do wizard e "Salvar" na última etapa.
 * Após salvar: SnackBar "Organização salva com sucesso" e volta à listagem.
 */
test('cria uma organização pelo wizard e a vê na listagem', async ({
  page,
}) => {
  const sufixo = Date.now();
  const tradeName = `E2E Org ${sufixo}`;
  const razaoSocial = `E2E Razao Social ${sufixo}`;
  const nomePresidente = `Presidente E2E ${sufixo}`;
  const cpf = gerarCpfValido();

  // ---- Login (organizador do seed de staging) -----------------------------
  await page.goto('/');
  await enableFlutterSemantics(page);

  await flutterFill(page, 'E-mail', ORGANIZER_EMAIL);
  await flutterFill(page, 'Senha', ORGANIZER_PASSWORD);
  await page.getByRole('button', { name: 'Entrar' }).click();

  await expect(page.getByText('Organizações')).toBeVisible({
    timeout: 20_000,
  });

  // ---- Listagem de organizações ------------------------------------------
  await page.getByText('Organizações').click();
  await expect(page).toHaveURL(/\/organizations$/, { timeout: 20_000 });

  // FAB "Nova organização" abre o wizard em /organizations/new.
  await page.getByRole('button', { name: 'Nova organização' }).click();
  await expect(page.getByText('Dados básicos')).toBeVisible({
    timeout: 20_000,
  });

  // ---- Etapa 1 — Identificação --------------------------------------------
  await flutterFill(page, 'Nome fantasia', tradeName);
  await flutterFill(page, 'Razão social', razaoSocial);
  await page.getByRole('button', { name: 'Continuar' }).click();

  // ---- Etapa 2 — Presidente -----------------------------------------------
  await expect(page.getByText('Nome do presidente')).toBeVisible();
  await flutterFill(page, 'Nome do presidente', nomePresidente);
  // CPF tem máscara no client; valida o valor mascarado final (11 dígitos).
  await flutterFill(
    page,
    'CPF do presidente',
    cpf,
    /^\d{3}\.\d{3}\.\d{3}-\d{2}$/,
  );
  await page.getByRole('button', { name: 'Continuar' }).click();

  // ---- Etapa 3 — Contato (opcionais) --------------------------------------
  await expect(page.getByText('E-mail (opcional)')).toBeVisible();
  await flutterFill(
    page,
    'E-mail (opcional)',
    `contato.e2e.${sufixo}@example.com`,
  );
  await page.getByRole('button', { name: 'Continuar' }).click();

  // ---- Etapa 4 — Localização (opcionais) ----------------------------------
  await expect(page.getByText('Cidade (opcional)')).toBeVisible();
  await flutterFill(page, 'Cidade (opcional)', 'São Paulo');
  await page.getByRole('button', { name: 'Continuar' }).click();

  // ---- Etapa 5 — Identidade (opcionais) -----------------------------------
  await expect(page.getByText('Prévia da marca')).toBeVisible();
  await page.getByRole('button', { name: 'Salvar' }).click();

  // ---- Confirmação: SnackBar + organização na listagem ---------------------
  await expect(page.getByText('Organização salva com sucesso')).toBeVisible({
    timeout: 20_000,
  });
  await expect(page.getByText(tradeName)).toBeVisible({ timeout: 20_000 });
});
