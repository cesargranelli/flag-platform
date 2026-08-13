CREATE TABLE platform.team_roster
(
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id    UUID        NOT NULL,
    athlete_id UUID        NOT NULL,
    status     VARCHAR(20) NOT NULL,
    created_at TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    created_by UUID,
    updated_by UUID,
    CONSTRAINT fk_team_roster_team
        FOREIGN KEY (team_id) REFERENCES platform.teams (id),
    CONSTRAINT fk_team_roster_athlete
        FOREIGN KEY (athlete_id) REFERENCES platform.athletes (id),
    CONSTRAINT uk_team_roster_team_athlete
        UNIQUE (team_id, athlete_id)
);
