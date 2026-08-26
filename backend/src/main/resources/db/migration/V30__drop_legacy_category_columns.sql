-- V30: limpeza da era de categorias — abordagem de RESET (#315/#319).
-- Diretriz do projeto: mudanças estruturantes em tabelas com
-- relacionamento vêm acompanhadas de reset dos dados afetados
-- (ambiente de desenvolvimento).
--
-- Remove os dados dependentes e depois as colunas category_id legadas,
-- caso ainda existam no schema (V24/V25 não aplicadas naquele banco).

-- 1) Constraints legadas conhecidas que referenciam category_id.
ALTER TABLE platform.conferences DROP CONSTRAINT IF EXISTS fk_conferences_category;
ALTER TABLE platform.conferences DROP CONSTRAINT IF EXISTS uk_conferences_category_name;
ALTER TABLE platform.divisions   DROP CONSTRAINT IF EXISTS fk_divisions_category;
ALTER TABLE platform.divisions   DROP CONSTRAINT IF EXISTS uk_divisions_category_conference_name;
ALTER TABLE platform.rounds      DROP CONSTRAINT IF EXISTS fk_rounds_category;
ALTER TABLE platform.rounds      DROP CONSTRAINT IF EXISTS uk_rounds_category_number;
ALTER TABLE platform.standings   DROP CONSTRAINT IF EXISTS fk_standings_category;
ALTER TABLE platform.standings   DROP CONSTRAINT IF EXISTS uk_standings_category_team;
ALTER TABLE platform.teams       DROP CONSTRAINT IF EXISTS fk_teams_category;
ALTER TABLE platform.teams       DROP CONSTRAINT IF EXISTS uk_teams_category_name;

-- 1) Colunas legadas (no-op quando já removidas pela V24).
ALTER TABLE platform.conferences DROP COLUMN IF EXISTS category_id;
ALTER TABLE platform.divisions   DROP COLUMN IF EXISTS category_id;
ALTER TABLE platform.rounds      DROP COLUMN IF EXISTS category_id;
ALTER TABLE platform.standings   DROP COLUMN IF EXISTS category_id;
ALTER TABLE platform.teams       DROP COLUMN IF EXISTS category_id;
