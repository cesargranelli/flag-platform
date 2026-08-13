CREATE TABLE platform.standings
(
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id    UUID    NOT NULL,
    team_id        UUID    NOT NULL,
    played         INTEGER NOT NULL DEFAULT 0,
    wins           INTEGER NOT NULL DEFAULT 0,
    draws          INTEGER NOT NULL DEFAULT 0,
    losses         INTEGER NOT NULL DEFAULT 0,
    goals_for      INTEGER NOT NULL DEFAULT 0,
    goals_against  INTEGER NOT NULL DEFAULT 0,
    points         INTEGER NOT NULL DEFAULT 0,
    created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP,
    created_by     UUID,
    updated_by     UUID,
    CONSTRAINT fk_standings_category
        FOREIGN KEY (category_id) REFERENCES platform.categories (id),
    CONSTRAINT fk_standings_team
        FOREIGN KEY (team_id) REFERENCES platform.teams (id),
    CONSTRAINT uk_standings_category_team
        UNIQUE (category_id, team_id)
);
