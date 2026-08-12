CREATE TABLE platform.competitions
(
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID         NOT NULL,
    name            VARCHAR(100) NOT NULL,
    description     VARCHAR(500),
    start_date      DATE,
    end_date        DATE,
    status          VARCHAR(20)  NOT NULL,
    created_at      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP,
    created_by      UUID,
    updated_by      UUID,
    CONSTRAINT fk_competitions_organization
        FOREIGN KEY (organization_id) REFERENCES platform.organizations (id),
    CONSTRAINT uk_competitions_organization_name
        UNIQUE (organization_id, name),
    CONSTRAINT ck_competitions_status
        CHECK (status IN ('DRAFT', 'PUBLISHED', 'FINISHED')),
    CONSTRAINT ck_competitions_dates
        CHECK (end_date IS NULL OR start_date IS NULL OR end_date >= start_date)
);
