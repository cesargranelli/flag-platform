#!/usr/bin/env node
/**
 * Seed de dados fake para o Flag Platform (issue #387).
 *
 * Cria via API REST uma carga realista para validação manual / demos:
 *   37 organizações (1 por tipo + 32 CLUB), 320 atletas masculinos,
 *   2 campos, 1 campeonato (rascunho), 32 times, 2 divisões (A/B),
 *   10 rodadas, 48 jogos e elenco (10 atletas por clube).
 *
 * Uso (a partir da raiz do monorepo):
 *   node e2e/seed/seed-fake-data.mjs
 *
 * Variáveis de ambiente (todas opcionais):
 *   API_BASE_URL   http://localhost:8080  (default)
 *   SEED_EMAIL     organizer@flag.test    (default)
 *   SEED_PASSWORD  Organizer@123          (default)
 *   SEED_CONCURRENCY  8                   (max. requisições simultâneas)
 *
 * IMPORTANTE: não é idempotente — rode `reset-fake-data.mjs` antes para
 * zerar uma carga anterior (trade names e CPFs são únicos).
 */

/* ---------------------------------------------------------------- config */
const API_BASE_URL = (process.env.API_BASE_URL || 'http://localhost:8080').replace(/\/$/, '');
const SEED_EMAIL = process.env.SEED_EMAIL || 'organizer@flag.test';
const SEED_PASSWORD = process.env.SEED_PASSWORD || 'Organizer@123';
const CONCURRENCY = Number(process.env.SEED_CONCURRENCY || 8);

const ORGANIZATION_TYPES = ['FEDERATION', 'LEAGUE', 'ASSOCIATION', 'UNIVERSITY', 'OTHER'];
const CLUBS_TOTAL = 32;
const ATHLETES_TOTAL = 320;
const VENUES_TOTAL = 2;
const DIVISIONS = ['A', 'B'];
const ROUNDS_TOTAL = 10;
const POSITIONS = ['QB', 'RB', 'WR', 'TE', 'C', 'DL', 'LB', 'DB', 'K', 'P'];

let token = null;

/* ------------------------------------------------------------ helpers */

/** Executa uma requisição HTTP à API e devolve o corpo (JSON) já parseado. */
async function request(method, path, { body, auth = true } = {}) {
  const headers = { 'Content-Type': 'application/json' };
  if (auth) {
    if (!token) throw new Error('Sem token de autenticação — faça login antes.');
    headers.Authorization = `Bearer ${token}`;
  }
  const res = await fetch(`${API_BASE_URL}${path}`, {
    method,
    headers,
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await res.text();
  let data = null;
  if (text) {
    try {
      data = JSON.parse(text);
    } catch {
      data = text;
    }
  }
  if (!res.ok) {
    throw new Error(
      `${method} ${path} -> ${res.status} ${res.statusText}: ${text || '(sem corpo)'}`,
    );
  }
  return data;
}

/** Calcula o dígito verificador de CPF (mesmo algoritmo do DocumentValidator). */
function digitoCpf(digitos, pesoInicial, limite) {
  let soma = 0;
  for (let i = 0; i < limite; i++) soma += digitos[i] * (pesoInicial - i);
  const resto = (soma * 10) % 11;
  return resto === 10 ? 0 : resto;
}

/** Gera um CPF válido (11 dígitos, verificadores corretos). */
function genCpf() {
  for (;;) {
    const base = Array.from({ length: 9 }, () => Math.floor(Math.random() * 10));
    // Rejeita sequências de um só dígito (ex.: 111.111.111-11) — CPF inválido.
    if (new Set(base).size === 1) continue;
    const d1 = digitoCpf(base, 10, 9);
    const d2 = digitoCpf([...base, d1], 11, 10);
    const cpf = [...base, d1, d2].join('');
    if (!cpfUsados.has(cpf)) {
      cpfUsados.add(cpf);
      return cpf;
    }
  }
}

/** Seleciona `n` posições distintas do conjunto de posições do flag. */
function genPositions(n = 2) {
  const bucket = [...POSITIONS];
  const picked = [];
  for (let i = 0; i < n && bucket.length; i++) {
    const idx = Math.floor(Math.random() * bucket.length);
    picked.push(bucket.splice(idx, 1)[0]);
  }
  return picked;
}

/** Executa `fn` sobre os itens com limite de concorrência, preservando a ordem. */
async function mapConcurrent(items, limit, fn) {
  const out = new Array(items.length);
  let cursor = 0;
  const workers = Array.from(
    { length: Math.min(limit, items.length) },
    async () => {
      while (cursor < items.length) {
        const idx = cursor++;
        out[idx] = await fn(items[idx], idx);
      }
    },
  );
  await Promise.all(workers);
  return out;
}

function fmtIsoLocal(d) {
  const p = (n, l = 2) => String(n).padStart(l, '0');
  return (
    `${d.getUTCFullYear()}-${p(d.getUTCMonth() + 1)}-${p(d.getUTCDate())}` +
    `T${p(d.getUTCHours())}:${p(d.getUTCMinutes())}:${p(d.getUTCSeconds())}`
  );
}

/** Gera nomes masculinos brasileiros únicos (primeiro + sobrenome). */
function genNames(total) {
  const first = [
    'João', 'Pedro', 'Lucas', 'Gabriel', 'Matheus', 'Rafael', 'Bruno', 'Gustavo',
    'Felipe', 'Thiago', 'Diego', 'André', 'Caio', 'Douglas', 'Eduardo', 'Vinícius',
    'Rodrigo', 'Marcelo', 'Renan', 'Igor', 'Leandro', 'Vitor', 'Daniel', 'Alex',
    'Fábio', 'Marcus', 'Wesley', 'César', 'Murilo', 'Otávio', 'Heitor', 'Enzo',
    'Davi', 'Benício', 'Miguel', 'Arthur', 'Bernardo', 'Samuel', 'Nicolas', 'Manuel',
  ];
  const last = [
    'Silva', 'Santos', 'Oliveira', 'Souza', 'Costa', 'Pereira', 'Almeida', 'Nascimento',
    'Lima', 'Araújo', 'Fernandes', 'Carvalho', 'Gomes', 'Martins', 'Rocha', 'Ribeiro',
    'Alves', 'Monteiro', 'Barbosa', 'Cardoso', 'Teixeira', 'Correia', 'Farias', 'Moraes',
    'Campos', 'Dias', 'Freitas', 'Vieira', 'Pinto', 'Moreira', 'Cavalcanti', 'Xavier',
    'Melo', 'Peixoto', 'Fonseca', 'Teles', 'Siqueira', 'Moura', 'Barros', 'Nunes',
  ];
  const used = new Set();
  const names = [];
  while (names.length < total) {
    const f = first[Math.floor(Math.random() * first.length)];
    const l = last[Math.floor(Math.random() * last.length)];
    const full = `${f} ${l}`;
    if (!used.has(full)) {
      used.add(full);
      names.push(full);
    }
  }
  return names;
}

/** Gera pares de times (round-robin) garantindo que cada time jogue 1x/rodada. */
function buildRoundRobin(teamIds) {
  const n = teamIds.length; // sempre par (32)
  const fixed = teamIds[0];
  const rest = [...teamIds.slice(1)];
  const rounds = [];
  for (let r = 0; r < n - 1; r++) {
    const games = [];
    const middle = [...rest];
    games.push([fixed, middle[middle.length - 1]]);
    for (let i = 0; i < (middle.length - 1) / 2; i++) {
      games.push([middle[i], middle[middle.length - 2 - i]]);
    }
    rounds.push(games);
    rest.unshift(rest.pop());
  }
  return rounds;
}

/* ------------------------------------------------------------- boot */
const cpfUsados = new Set();
const VALID_PRESIDENT_CPF = genCpf();

async function login() {
  const data = await request('POST', '/api/v1/auth/login', {
    auth: false,
    body: { email: SEED_EMAIL, password: SEED_PASSWORD },
  });
  token = data.token;
  console.log(`[auth] autenticado como ${SEED_EMAIL}`);
}

async function createOrganizations() {
  const orgs = [];
  const slug = (name) =>
    name.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase()
      .replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');

  // 1 org de cada tipo especial
  const special = [
    { type: 'FEDERATION', trade: 'Federação Nacional' },
    { type: 'LEAGUE', trade: 'Liga Nacional' },
    { type: 'ASSOCIATION', trade: 'Associação Brasileira' },
    { type: 'UNIVERSITY', trade: 'Universidade Nacional' },
    { type: 'OTHER', trade: 'Instituto Esporte' },
  ];
  // 32 clubes
  for (let i = 1; i <= CLUBS_TOTAL; i++) special.push({ type: 'CLUB', trade: `Clube ${String(i).padStart(2, '0')}` });

  for (const { type, trade } of special) {
    const body = {
      legalName: `${trade} Ltda`,
      tradeName: trade,
      abbreviation: trade.split(' ').map((w) => w[0]).join('').toUpperCase().slice(0, 5),
      organizationType: type,
      document: null,
      documentType: null,
      presidentName: 'Presidente Seed',
      presidentCpf: VALID_PRESIDENT_CPF,
      email: `${slug(trade)}@flag.test`,
      country: 'BR',
      timezone: 'America/Sao_Paulo',
      locale: 'pt-BR',
    };
    const created = await request('POST', '/api/v1/organizations', { body });
    orgs.push({ id: created.id, type, tradeName: trade });
    console.log(`[organizations]\t${type.padEnd(10)} ${trade} -> ${created.id}`);
  }
  return orgs;
}

async function createVenues(firstOrgId) {
  const venues = [];
  for (let i = 1; i <= VENUES_TOTAL; i++) {
    const body = {
      organizationId: firstOrgId,
      name: `Campo ${String(i).padStart(2, '0')}`,
      address: `Av. do Esporte ${100 + i}, São Paulo - SP`,
      mapsUrl: `https://maps.example.com/campo-${i}`,
    };
    const created = await request('POST', '/api/v1/venues', { body });
    venues.push({ id: created.id, name: created.name });
    console.log(`[venues]\t${created.name} -> ${created.id}`);
  }
  return venues;
}

async function createAthletes(count) {
  const names = genNames(count);
  const results = await mapConcurrent(names, CONCURRENCY, async (name, i) => {
    const body = {
      name,
      cpf: genCpf(),
      nickname: `Atleta ${String(i + 1).padStart(3, '0')}`,
      positions: genPositions(2),
      number: (i % 99) + 1,
    };
    const created = await request('POST', '/api/v1/athletes', { body });
    return created.id;
  });
  if (results.length % 100 === 0) console.log(`[athletes]\t${results.length}/${count} criados`);
  console.log(`[athletes]\t${results.length} atletas criados`);
  return results;
}

async function createCompetition(firstOrgId) {
  const body = {
    organizationId: firstOrgId,
    name: 'Campeonato Seed Flag',
    description: 'Carga fake gerada por e2e/seed/seed-fake-data.mjs',
    modality: 'FLAG_5X5',
    gender: 'MALE',
    ageGroup: 'ADULT',
    groupingType: 'DIVISIONS',
  };
  const created = await request('POST', '/api/v1/competitions', { body });
  console.log(`[competition]\t${created.name} -> ${created.id} (status ${created.status})`);
  return created;
}

async function associateClubs(competitionId, clubs) {
  const results = [];
  for (const club of clubs) {
    const team = await request('POST', `/api/v1/competitions/${competitionId}/clubs`, {
      body: { organizationId: club.id },
    });
    results.push(team);
    console.log(`[teams]\t${team.name} -> ${team.id}`);
  }
  return results;
}

async function createDivisions(competitionId) {
  const divisions = {};
  for (const name of DIVISIONS) {
    const created = await request('POST', `/api/v1/competitions/${competitionId}/divisions`, {
      body: { name },
    });
    divisions[name] = created.id;
    console.log(`[divisions]\t${name} -> ${created.id}`);
  }
  return divisions;
}

async function assignDivisions(teams, divisions) {
  // 16 times na divisão A, 16 na B.
  const half = Math.floor(teams.length / 2);
  for (let i = 0; i < teams.length; i++) {
    const team = teams[i];
    const divisionId = i < half ? divisions.A : divisions.B;
    const body = {
      organizationId: team.organizationId,
      competitionId: team.competitionId,
      divisionId,
      name: team.name,
    };
    const updated = await request('PUT', `/api/v1/teams/${team.id}`, { body });
    console.log(`[teams/div]\t${updated.name} -> divisão ${i < half ? 'A' : 'B'}`);
  }
}

async function createRounds(competitionId) {
  const rounds = [];
  for (let n = 1; n <= ROUNDS_TOTAL; n++) {
    const body = {
      competitionId,
      number: n,
      name: `Rodada ${String(n).padStart(2, '0')}`,
      type: 'REGULAR',
    };
    const created = await request('POST', '/api/v1/rounds', { body });
    rounds.push(created);
    console.log(`[rounds]\t${created.name} -> ${created.id}`);
  }
  return rounds;
}

async function createGames(teamIds, rounds, venues) {
  // Round-robin: 3 rodadas = 48 jogos, cada time aparece exatamente 3x.
  const rr = buildRoundRobin(teamIds);
  const usedRounds = rr.slice(0, 3);

  // Distribui as 3 rodadas do round-robin pelas 10 rodadas do campeonato,
  // mantendo cada time em rodadas diferentes (sem time 2x na mesma rodada).
  const groups = [
    { chRounds: [0, 1, 2, 3], games: usedRounds[0] },   // 16 jogos -> 4/rodada
    { chRounds: [4, 5, 6, 7], games: usedRounds[1] },   // 16 jogos -> 4/rodada
    { chRounds: [8, 9], games: usedRounds[2] },         // 16 jogos -> 8/rodada
  ];

  let total = 0;
  for (const group of groups) {
    const per = Math.ceil(group.games.length / group.chRounds.length);
    let gameIdx = 0;
    for (const chRound of group.chRounds) {
      for (let pos = 0; pos < per && gameIdx < group.games.length; pos++, gameIdx++) {
        const [homeTeamId, awayTeamId] = group.games[gameIdx];
        const venueId = venues[pos % venues.length].id;
        const date = new Date(Date.UTC(2026, 8, 1 + chRound, 9 + pos, 0, 0));
        const body = {
          roundId: rounds[chRound].id,
          homeTeamId,
          awayTeamId,
          venueId,
          scheduledAt: fmtIsoLocal(date),
        };
        await request('POST', '/api/v1/games', { body });
        total++;
        if (total % 12 === 0) console.log(`[games]\t${total}/48 criados`);
      }
    }
  }
  console.log(`[games]\t${total} jogos criados`);
}

async function populateRosters(teams, athleteIds) {
  let created = 0;
  for (let t = 0; t < teams.length; t++) {
    const team = teams[t];
    const slice = athleteIds.slice(t * 10, t * 10 + 10);
    for (let a = 0; a < slice.length; a++) {
      const body = {
        athleteId: slice[a],
        nickname: `Atleta ${String(t + 1).padStart(2, '0')}.${a + 1}`,
        number: a + 1,
      };
      await request('POST', `/api/v1/teams/${team.id}/roster`, { body });
      created++;
    }
    if (t % 8 === 0) console.log(`[roster]\t${t + 1}/32 times com elenco`);
  }
  console.log(`[roster]\t${created} inscrições criadas`);
}

/* ------------------------------------------------------------- main */
async function main() {
  console.log(`[seed] API: ${API_BASE_URL}`);
  await login();

  const orgs = await createOrganizations();
  const firstOrg = orgs[0];
  const clubs = orgs.filter((o) => o.type === 'CLUB');
  console.log(`[seed] organizações: ${orgs.length} (${clubs.length} clubes)`);

  const venues = await createVenues(firstOrg.id);
  const athleteIds = await createAthletes(ATHLETES_TOTAL);
  const competition = await createCompetition(firstOrg.id);
  const teams = await associateClubs(competition.id, clubs);
  const divisions = await createDivisions(competition.id);
  await assignDivisions(teams, divisions);
  const rounds = await createRounds(competition.id);
  await createGames(teams.map((t) => t.id), rounds, venues);
  await populateRosters(teams, athleteIds);

  console.log('\n[seed] Resumo da carga:');
  console.log(`  organizações  ${orgs.length}`);
  console.log(`  atletas       ${athleteIds.length}`);
  console.log(`  campos        ${venues.length}`);
  console.log(`  campeonato    ${competition.name}`);
  console.log(`  times         ${teams.length}`);
  console.log(`  divisões      ${Object.keys(divisions).length}`);
  console.log(`  rodadas       ${rounds.length}`);
  console.log('  jogos         48');
  console.log('  elenco        320 inscrições (10 por time)');
  console.log('\n[seed] concluído com sucesso.');
}

main().catch((err) => {
  console.error(`\n[seed] FALHA: ${err.message}`);
  console.error('Dica: rode e2e/seed/reset-fake-data.mjs para zerar e tentar de novo.');
  process.exitCode = 1;
});
