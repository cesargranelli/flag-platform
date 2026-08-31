-- V33: Refatoração Team/Roster/Season (ADR-006)
-- Hierarquia: Organization → Team → CompetitionTeam → Roster → RosterEntry → Athlete
-- Ambiente dev: truncate completo das tabelas afetadas.

-- 1) Limpeza de dados dependentes
DELETE FROM platform.score_events;
DELETE FROM platform.checkins;
DELETE FROM platform.team_roster;
DELETE FROM platform.standings;
DELETE FROM platform.plays;
DELETE FROM platform.games;

-- 2) Dropar tabelas antigas
DROP TABLE IF EXISTS platform.team_roster CASCADE;
DROP TABLE IF EXISTS platform.teams CASCADE;

-- 3) Criar tabela team (sub-entity de Organization)
CREATE TABLE platform.team
(
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID         NOT NULL,
    name            VARCHAR(255) NOT NULL,
    short_name      VARCHAR(50),
    sport_name      VARCHAR(255),
    logo_url        VARCHAR(500),
    status          VARCHAR(20)  DEFAULT 'ACTIVE',
    created_at      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP,
    created_by      UUID,
    updated_by      UUID,
    CONSTRAINT fk_team_organization
        FOREIGN KEY (organization_id) REFERENCES platform.organizations (id)
);

CREATE INDEX idx_team_organization ON platform.team (organization_id);

-- 4) Criar tabela competition_team (join table)
CREATE TABLE platform.competition_team
(
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    competition_id UUID NOT NULL,
    team_id       UUID NOT NULL,
    division_id   UUID,
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP,
    created_by    UUID,
    updated_by    UUID,
    CONSTRAINT fk_competition_team_competition
        FOREIGN KEY (competition_id) REFERENCES platform.competitions (id),
    CONSTRAINT fk_competition_team_team
        FOREIGN KEY (team_id) REFERENCES platform.team (id),
    CONSTRAINT fk_competition_team_division
        FOREIGN KEY (division_id) REFERENCES platform.divisions (id),
    CONSTRAINT uk_competition_team
        UNIQUE (competition_id, team_id)
);

CREATE INDEX idx_competition_team_competition ON platform.competition_team (competition_id);
CREATE INDEX idx_competition_team_team ON platform.competition_team (team_id);

-- 5) Criar tabela roster (elenco por time/competição)
CREATE TABLE platform.roster
(
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id         UUID         NOT NULL,
    competition_id  UUID         NOT NULL,
    name            VARCHAR(255),
    season          VARCHAR(50)  NOT NULL DEFAULT '2026',
    status          VARCHAR(20)  DEFAULT 'ACTIVE',
    created_at      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP,
    created_by      UUID,
    updated_by      UUID,
    CONSTRAINT fk_roster_team
        FOREIGN KEY (team_id) REFERENCES platform.team (id),
    CONSTRAINT fk_roster_competition
        FOREIGN KEY (competition_id) REFERENCES platform.competitions (id),
    CONSTRAINT uk_roster_team_competition
        UNIQUE (team_id, competition_id)
);

CREATE INDEX idx_roster_team ON platform.roster (team_id);
CREATE INDEX idx_roster_competition ON platform.roster (competition_id);

-- 6) Criar tabela team_roster (nova — referencia roster_id)
CREATE TABLE platform.team_roster
(
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    roster_id   UUID         NOT NULL,
    athlete_id  UUID         NOT NULL,
    status      VARCHAR(20)  NOT NULL,
    nickname    VARCHAR(100),
    number      INTEGER,
    created_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP,
    created_by  UUID,
    updated_by  UUID,
    CONSTRAINT fk_team_roster_roster
        FOREIGN KEY (roster_id) REFERENCES platform.roster (id),
    CONSTRAINT fk_team_roster_athlete
        FOREIGN KEY (athlete_id) REFERENCES platform.athletes (id),
    CONSTRAINT uk_team_roster_roster_athlete
        UNIQUE (roster_id, athlete_id)
);

-- 7) Adicionar campo season na tabela competitions
ALTER TABLE platform.competitions
    ADD COLUMN season VARCHAR(50) NOT NULL DEFAULT '2026';
