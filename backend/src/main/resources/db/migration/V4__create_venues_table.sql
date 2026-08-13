CREATE TABLE platform.venues
(
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID         NOT NULL,
    name            VARCHAR(150) NOT NULL,
    address         VARCHAR(500),
    maps_url        VARCHAR(500),
    created_at      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP,
    created_by      UUID,
    updated_by      UUID,
    CONSTRAINT fk_venues_organization
        FOREIGN KEY (organization_id) REFERENCES platform.organizations (id),
    CONSTRAINT uk_venues_organization_name
        UNIQUE (organization_id, name)
);
