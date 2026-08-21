-- V24: Campeonato como fluxo único — remove categorias
-- Competição ganha modalidade/gênero/faixa etária
ALTER TABLE platform.competitions
    ADD COLUMN modality_id UUID,
    ADD COLUMN gender VARCHAR(20),
    ADD COLUMN age_group VARCHAR(20);

-- backfill a partir da primeira categoria ativa de cada competição
UPDATE platform.competitions c
SET modality_id = cat.modality_id,
    gender      = cat.gender,
    age_group   = cat.age_group
FROM (
    SELECT DISTINCT ON (competition_id) competition_id, modality_id, gender, age_group
    FROM platform.categories
    WHERE deleted_at IS NULL
    ORDER BY competition_id, created_at
) cat
WHERE c.id = cat.competition_id;

ALTER TABLE platform.competitions
    ADD CONSTRAINT fk_competitions_modality
        FOREIGN KEY (modality_id) REFERENCES platform.modalities (id);

-- Conferences passam a pertencer ao campeonato
ALTER TABLE platform.conferences
    ADD COLUMN competition_id UUID;
UPDATE platform.conferences cf
SET competition_id = cat.competition_id
FROM platform.categories cat
WHERE cf.category_id = cat.id;
ALTER TABLE platform.conferences
    DROP CONSTRAINT fk_conferences_category,
    DROP COLUMN category_id;
ALTER TABLE platform.conferences
    ALTER COLUMN competition_id SET NOT NULL,
    ADD CONSTRAINT fk_conferences_competition
        FOREIGN KEY (competition_id) REFERENCES platform.competitions (id);

-- Divisions passam a pertencer ao campeonato
ALTER TABLE platform.divisions
    ADD COLUMN competition_id UUID;
UPDATE platform.divisions d
SET competition_id = cat.competition_id
FROM platform.categories cat
WHERE d.category_id = cat.id;
ALTER TABLE platform.divisions
    DROP CONSTRAINT fk_divisions_category,
    DROP COLUMN category_id;
ALTER TABLE platform.divisions
    ALTER COLUMN competition_id SET NOT NULL,
    ADD CONSTRAINT fk_divisions_competition
        FOREIGN KEY (competition_id) REFERENCES platform.competitions (id);
DROP INDEX IF EXISTS uk_divisions_category_conference_name;
CREATE UNIQUE INDEX uk_divisions_competition_conference_name
    ON platform.divisions (competition_id, COALESCE(conference_id, '00000000-0000-0000-0000-000000000000'), name);

-- Teams: inscrição do clube (organization) no campeonato
-- Dados legados de times não têm organização; são descartados (ambiente dev).
DELETE FROM platform.score_events WHERE team_id IN (SELECT id FROM platform.teams);
DELETE FROM platform.checkins WHERE team_id IN (SELECT id FROM platform.teams);
DELETE FROM platform.team_roster WHERE team_id IN (SELECT id FROM platform.teams);
DELETE FROM platform.standings WHERE team_id IN (SELECT id FROM platform.teams);
DELETE FROM platform.games
    WHERE home_team_id IN (SELECT id FROM platform.teams)
       OR away_team_id IN (SELECT id FROM platform.teams);
DELETE FROM platform.teams;

ALTER TABLE platform.teams
    DROP CONSTRAINT fk_teams_category,
    DROP COLUMN category_id,
    ADD COLUMN organization_id UUID,
    ADD COLUMN competition_id UUID,
    ALTER COLUMN name DROP NOT NULL;
ALTER TABLE platform.teams
    ALTER COLUMN organization_id SET NOT NULL,
    ALTER COLUMN competition_id SET NOT NULL,
    ADD CONSTRAINT fk_teams_organization
        FOREIGN KEY (organization_id) REFERENCES platform.organizations (id),
    ADD CONSTRAINT fk_teams_competition
        FOREIGN KEY (competition_id) REFERENCES platform.competitions (id);

-- Rounds passam a pertencer ao campeonato
ALTER TABLE platform.rounds
    ADD COLUMN competition_id UUID;
UPDATE platform.rounds r
SET competition_id = cat.competition_id
FROM platform.categories cat
WHERE r.category_id = cat.id;
ALTER TABLE platform.rounds
    DROP CONSTRAINT fk_rounds_category,
    DROP COLUMN category_id;
ALTER TABLE platform.rounds
    ALTER COLUMN competition_id SET NOT NULL,
    ADD CONSTRAINT fk_rounds_competition
        FOREIGN KEY (competition_id) REFERENCES platform.competitions (id);

-- Standings passam a pertencer ao campeonato
ALTER TABLE platform.standings
    ADD COLUMN competition_id UUID;
UPDATE platform.standings s
SET competition_id = cat.competition_id
FROM platform.categories cat
WHERE s.category_id = cat.id;
ALTER TABLE platform.standings
    DROP CONSTRAINT fk_standings_category,
    DROP COLUMN category_id;
ALTER TABLE platform.standings
    ALTER COLUMN competition_id SET NOT NULL,
    ADD CONSTRAINT fk_standings_competition
        FOREIGN KEY (competition_id) REFERENCES platform.competitions (id);

-- Remove o conceito de categoria
DROP TABLE platform.categories;