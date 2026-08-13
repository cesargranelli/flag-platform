CREATE TABLE platform.games
(
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    round_id     UUID        NOT NULL,
    home_team_id UUID        NOT NULL,
    away_team_id UUID        NOT NULL,
    venue_id     UUID,
    scheduled_at TIMESTAMP,
    status       VARCHAR(20) NOT NULL DEFAULT 'SCHEDULED',
    created_at   TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP,
    created_by   UUID,
    updated_by   UUID,
    CONSTRAINT fk_games_round
        FOREIGN KEY (round_id) REFERENCES platform.rounds (id),
    CONSTRAINT fk_games_home_team
        FOREIGN KEY (home_team_id) REFERENCES platform.teams (id),
    CONSTRAINT fk_games_away_team
        FOREIGN KEY (away_team_id) REFERENCES platform.teams (id),
    CONSTRAINT fk_games_venue
        FOREIGN KEY (venue_id) REFERENCES platform.venues (id),
    CONSTRAINT uk_games_round_home_away
        UNIQUE (round_id, home_team_id, away_team_id),
    CONSTRAINT chk_games_teams_differ
        CHECK (home_team_id <> away_team_id)
);
