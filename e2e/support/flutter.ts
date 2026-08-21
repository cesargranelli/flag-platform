import { type Locator, type Page, expect } from '@playwright/test';

/**
 * Helpers de interação com apps Flutter Web renderizados em CanvasKit.
 *
 * O Flutter Web por padrão renderiza a UI inteira em um <canvas>: o texto
 * NÃO fica no DOM até a árvore de acessibilidade (semantics) ser habilitada.
 * A habilitação é feita clicando no elemento oculto
 * `<flt-semantics-placeholder aria-label="Enable accessibility">`.
 * A partir daí, o Flutter expõe nós `<flt-semantics>` com roles e
 * aria-labels que o Playwright enxerga via getByRole/getByText/getByLabel.
 */

const BOOT_TIMEOUT = 30_000;

/** Aguarda o bootstrap do app e habilita a árvore de acessibilidade (idempotente). */
export async function enableFlutterSemantics(page: Page): Promise<void> {
  // O app só precisa EXISTIR (attached): em Chromium headless o flt-glass-pane
  // é reportado como hidden mesmo com o app renderizando no canvas, então
  // aguardar "visible" trava o teste. Conteúdo real só aparece no DOM após
  // habilitar a árvore de acessibilidade.
  await page.waitForSelector('flt-glass-pane', {
    state: 'attached',
    timeout: BOOT_TIMEOUT,
  });

  // Semantics já habilitadas? Nada a fazer.
  if ((await page.$('flt-semantics')) !== null) return;

  // Clica no placeholder oculto. Em versões recentes do Flutter ele fica no
  // light DOM; o fallback tenta o shadowRoot do flt-glass-pane (legado).
  const clicked = await page.evaluate(() => {
    const el =
      document.querySelector<HTMLElement>('flt-semantics-placeholder') ??
      document
        .querySelector('flt-glass-pane')
        ?.shadowRoot?.querySelector<HTMLElement>(
          'flt-semantics-placeholder',
        );
    if (el) {
      el.click();
      return true;
    }
    return false;
  });

  if (!clicked) {
    throw new Error(
      'Flutter Web: flt-semantics-placeholder não encontrado; ' +
        'não foi possível habilitar a acessibilidade (semantics).',
    );
  }

  // Os nós flt-semantics só surgem após o app montar a árvore de acessibilidade
  // — se este passo falhar, o app não chegou ao primeiro frame (investigar boot).
  await page.waitForSelector('flt-semantics', { timeout: 30_000 });
}

/**
 * Localiza um campo de texto do Flutter Web pelo label visível.
 *
 * TextFormField com `labelText` gera um nó flt-semantics com
 * `role="textbox"` e aria-label igual ao label. O `getByRole` cobre o caso
 * padrão; o fallback por aria-label cobre variações de marcação do engine.
 */
export function flutterField(page: Page, label: string): Locator {
  return page
    .getByRole('textbox', { name: label })
    .or(page.locator(`flt-semantics[aria-label*="${label}"]`));
}

/**
 * Preenche um campo do Flutter Web como um usuário: clica (foca) e digita.
 *
 * O clique no flt-semantics cai na posição do campo no canvas, o Flutter cria
 * o <input> real sob demanda e a digitação via teclado é recebida por ele.
 * `verify` valida o valor final do input real (exato ou RegExp — use RegExp
 * para campos com máscara, ex.: CPF/CNPJ/telefone). Passe `false` para pular.
 */
export async function flutterFill(
  page: Page,
  label: string,
  value: string,
  verify: string | RegExp | false = value,
): Promise<void> {
  const field = flutterField(page, label).first();
  await field.click();
  // delay baixo para o engine do Flutter acompanhar (máscaras, formatters).
  await page.keyboard.type(value, { delay: 25 });

  if (verify !== false) {
    await expect(field.locator('input').first()).toHaveValue(verify, {
      timeout: 5_000,
    });
  }
}

/** Clique em um elemento do Flutter Web com auto-wait do Playwright. */
export async function flutterTap(page: Page, target: Locator): Promise<void> {
  await target.click();
}
