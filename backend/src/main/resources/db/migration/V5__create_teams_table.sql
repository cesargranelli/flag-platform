CREATE TABLE platform.teams
(
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID         NOT NULL,
    name        VARCHAR(150) NOT NULL,
    short_name  VARCHAR(20),
    logo_url    VARCHAR(500),
    created_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP,
    created_by  UUID,
    updated_by  UUID,
    CONSTRAINT fk_teams_category
        FOREIGN KEY (category_id) REFERENCES platform.categories (id),
    CONSTRAINT uk_teams_category_name
        UNIQUE (category_id, name)
);
