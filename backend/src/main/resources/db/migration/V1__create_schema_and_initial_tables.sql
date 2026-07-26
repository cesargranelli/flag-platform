-- V1__create_schema_and_initial_tables.sql
-- Flag Platform - Initial Schema

CREATE SCHEMA IF NOT EXISTS platform;

SET search_path TO platform;

-- Organization
CREATE TABLE organization (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        VARCHAR(150) NOT NULL,
    slug        VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    logo_url    VARCHAR(500),
    active      BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Competition
CREATE TABLE competition (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organization(id),
    name            VARCHAR(150) NOT NULL,
    slug            VARCHAR(100) NOT NULL,
    season          VARCHAR(20),
    status          VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    start_date      DATE,
    end_date        DATE,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (organization_id, slug)
);

-- Category
CREATE TABLE category (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    competition_id UUID NOT NULL REFERENCES competition(id),
    name           VARCHAR(100) NOT NULL,
    description    VARCHAR(255),
    created_at     TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Venue (campo)
CREATE TABLE venue (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organization(id),
    name           VARCHAR(150) NOT NULL,
    address        VARCHAR(500),
    maps_url       VARCHAR(500),
    active         BOOLEAN NOT NULL DEFAULT TRUE,
    created_at     TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Team
CREATE TABLE team (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID NOT NULL REFERENCES category(id),
    name        VARCHAR(150) NOT NULL,
    short_name  VARCHAR(20),
    logo_url    VARCHAR(500),
    active      BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Round
CREATE TABLE round (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID NOT NULL REFERENCES category(id),
    number      INTEGER NOT NULL,
    name        VARCHAR(100),
    type        VARCHAR(20) NOT NULL DEFAULT 'REGULAR',
    created_at  TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (category_id, number)
);

-- Game
CREATE TABLE game (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    round_id      UUID NOT NULL REFERENCES round(id),
    venue_id      UUID REFERENCES venue(id),
    home_team_id  UUID NOT NULL REFERENCES team(id),
    away_team_id  UUID NOT NULL REFERENCES team(id),
    scheduled_at  TIMESTAMP,
    status        VARCHAR(20) NOT NULL DEFAULT 'SCHEDULED',
    home_score    INTEGER,
    away_score    INTEGER,
    created_at    TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Standing
CREATE TABLE standing (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id  UUID NOT NULL REFERENCES category(id),
    team_id      UUID NOT NULL REFERENCES team(id),
    played       INTEGER NOT NULL DEFAULT 0,
    wins         INTEGER NOT NULL DEFAULT 0,
    draws        INTEGER NOT NULL DEFAULT 0,
    losses       INTEGER NOT NULL DEFAULT 0,
    goals_for    INTEGER NOT NULL DEFAULT 0,
    goals_against INTEGER NOT NULL DEFAULT 0,
    points       INTEGER NOT NULL DEFAULT 0,
    updated_at   TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (category_id, team_id)
);

-- Indexes
CREATE INDEX idx_competition_organization ON competition(organization_id);
CREATE INDEX idx_category_competition ON category(competition_id);
CREATE INDEX idx_team_category ON team(category_id);
CREATE INDEX idx_round_category ON round(category_id);
CREATE INDEX idx_game_round ON game(round_id);
CREATE INDEX idx_game_status ON game(status);
CREATE INDEX idx_standing_category ON standing(category_id);