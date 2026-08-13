CREATE TABLE platform.rounds
(
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID        NOT NULL,
    number      INTEGER     NOT NULL,
    name        VARCHAR(100),
    type        VARCHAR(20) NOT NULL DEFAULT 'REGULAR',
    created_at  TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP,
    created_by  UUID,
    updated_by  UUID,
    CONSTRAINT fk_rounds_category
        FOREIGN KEY (category_id) REFERENCES platform.categories (id),
    CONSTRAINT uk_rounds_category_number
        UNIQUE (category_id, number)
);
