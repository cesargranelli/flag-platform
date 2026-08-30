#!/usr/bin/env node
/**
 * Zera a carga fake criada por `seed-fake-data.mjs` (issue #387).
 *
 * Dados de dev/seed são descartáveis: o script TRUNCA as tabelas do
 * PostgreSQL (schema `platform`) usando `TRUNCATE ... CASCADE`, o que limpa
 * também as tabelas relacionadas (athlete_positions, team_roster,
 * score_events, standings, checkins, etc.).
 *
 * Uso (a partir da raiz do monorepo):
 *   node e2e/seed/reset-fake-data.mjs
 *
 * Requer o cliente `psql` no PATH e um Postgres acessível. Conexão via
 * variáveis de ambiente (padrões do docker-compose de dev):
 *   PGHOST=localhost  PGPORT=5432  PGDATABASE=flagplatform
 *   PGUSER=flagplatform  PGPASSWORD=flagplatform
 *   PLATFORM_SCHEMA=platform   (schema a limpar)
 */

import { execFileSync } from 'node:child_process';
import path from 'node:path';

const SCHEMA = process.env.PLATFORM_SCHEMA || 'platform';
const conn = {
  PGHOST: process.env.PGHOST || 'localhost',
  PGPORT: process.env.PGPORT || '5432',
  PGDATABASE: process.env.PGDATABASE || 'flagplatform',
  PGUSER: process.env.PGUSER || 'flagplatform',
  PGPASSWORD: process.env.PGPASSWORD || 'flagplatform',
};

// Tabelas raiz da carga fake. `CASCADE` trunca também as que referenciam
// estas (athlete_positions, team_roster, score_events, standings, ...).
const core = [
  'organizations',
  'athletes',
  'venues',
  'competitions',
  'conferences',
  'divisions',
  'teams',
  'rounds',
  'games',
];

const qualified = core.map((t) => `${SCHEMA}.${t}`);

const sql = `TRUNCATE TABLE ${qualified.join(', ')} RESTART IDENTITY CASCADE;`;

console.log('[reset] Tabelas a truncar:');
core.forEach((t) => console.log(`  platform.${t}`));
console.log(`[reset] conexão: ${conn.PGUSER}@${conn.PGHOST}:${conn.PGPORT}/${conn.PGDATABASE}`);

try {
  execFileSync('psql', ['-v', 'ON_ERROR_STOP=1', '-c', sql], {
    env: { ...process.env, ...conn },
    stdio: 'inherit',
  });
  console.log('\n[reset] Carga fake removida com sucesso.');
} catch (err) {
  console.error(`\n[reset] FALHA: ${err.message}`);
  console.error(
    'Certifique-se de que o cliente `psql` está no PATH e que o Postgres está no ar.',
  );
  process.exitCode = 1;
}
