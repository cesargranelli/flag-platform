CREATE TABLE platform.categories
(
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    competition_id UUID         NOT NULL,
    name           VARCHAR(100) NOT NULL,
    created_at     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP,
    created_by     UUID,
    updated_by     UUID,
    CONSTRAINT fk_categories_competition
        FOREIGN KEY (competition_id) REFERENCES platform.competitions (id),
    CONSTRAINT uk_categories_competition_name
        UNIQUE (competition_id, name)
);
