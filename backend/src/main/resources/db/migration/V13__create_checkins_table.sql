CREATE TABLE platform.checkins
(
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    game_id      UUID        NOT NULL,
    team_id      UUID        NOT NULL,
    athlete_id   UUID        NOT NULL,
    status       VARCHAR(20) NOT NULL,
    validated_by UUID,
    validated_at TIMESTAMP,
    created_at   TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP,
    created_by   UUID,
    updated_by   UUID,
    CONSTRAINT fk_checkins_game
        FOREIGN KEY (game_id) REFERENCES platform.games (id),
    CONSTRAINT fk_checkins_team
        FOREIGN KEY (team_id) REFERENCES platform.teams (id),
    CONSTRAINT fk_checkins_athlete
        FOREIGN KEY (athlete_id) REFERENCES platform.athletes (id),
    CONSTRAINT uk_checkins_game_athlete
        UNIQUE (game_id, athlete_id)
);
