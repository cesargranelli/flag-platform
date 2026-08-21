-- V25: Campeonato como fluxo único — correção das remoções de categorias
-- Conferences passam a pertencer ao campeonato - complemento
ALTER TABLE platform.conferences
-- DROP CONSTRAINT uk_conferences_category_name,
    ADD CONSTRAINT uk_conferences_competition_name UNIQUE (competition_id, name);

-- Teams: inscrição do clube (organization) no campeonato
-- Dados legados de times não têm organização; são descartados (ambiente dev). - complemento
ALTER TABLE platform.teams
-- DROP CONSTRAINT uk_teams_category_name,
    ADD CONSTRAINT uk_teams_competition_organization UNIQUE (competition_id, organization_id);

-- Rounds passam a pertencer ao campeonato - complemento
ALTER TABLE platform.rounds
-- DROP CONSTRAINT uk_rounds_category_number,
    ADD CONSTRAINT uk_rounds_competition_number UNIQUE (competition_id, number);

-- Standings passam a pertencer ao campeonato - complemento
ALTER TABLE platform.standings
-- DROP CONSTRAINT uk_standings_category_team,
    ADD CONSTRAINT uk_standings_competition_team UNIQUE (competition_id, team_id);