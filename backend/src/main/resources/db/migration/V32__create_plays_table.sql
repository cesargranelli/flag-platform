CREATE TABLE platform.plays
(
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    game_id       UUID         NOT NULL,
    team_id       UUID         NOT NULL,
    player_name   VARCHAR(100) NOT NULL,
    receiver_name VARCHAR(100),
    play_type     VARCHAR(30)  NOT NULL,
    description   TEXT,
    yards         INTEGER      DEFAULT 0,
    quarter       VARCHAR(5),
    time          VARCHAR(10),
    is_first_down BOOLEAN      DEFAULT FALSE,
    is_touchdown  BOOLEAN      DEFAULT FALSE,
    is_turnover   BOOLEAN      DEFAULT FALSE,
    created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP,
    created_by    UUID,
    updated_by    UUID,
    CONSTRAINT fk_plays_game
        FOREIGN KEY (game_id) REFERENCES platform.games (id),
    CONSTRAINT fk_plays_team
        FOREIGN KEY (team_id) REFERENCES platform.teams (id)
);

CREATE INDEX idx_plays_game_id ON platform.plays (game_id);
CREATE INDEX idx_plays_team_id ON platform.plays (team_id);
