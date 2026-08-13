CREATE TABLE platform.score_events
(
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    game_id    UUID      NOT NULL,
    team_id    UUID      NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_score_events_game
        FOREIGN KEY (game_id) REFERENCES platform.games (id),
    CONSTRAINT fk_score_events_team
        FOREIGN KEY (team_id) REFERENCES platform.teams (id)
);
