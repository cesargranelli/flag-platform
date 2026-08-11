CREATE SCHEMA IF NOT EXISTS platform;

CREATE TABLE platform.organizations
(
    id                UUID PRIMARY KEY      DEFAULT gen_random_uuid(),
    legal_name        VARCHAR(150) NOT NULL,
    trade_name        VARCHAR(100) NOT NULL,
    abbreviation      VARCHAR(20),
    organization_type VARCHAR(30)  NOT NULL,
    email             VARCHAR(150),
    phone             VARCHAR(30),
    website           VARCHAR(255),
    instagram         VARCHAR(100),
    country           VARCHAR(2)   NOT NULL,
    state             VARCHAR(100),
    city              VARCHAR(100),
    logo_url          VARCHAR(500),
    primary_color     VARCHAR(7),
    secondary_color   VARCHAR(7),
    timezone          VARCHAR(60)  NOT NULL,
    locale            VARCHAR(10)  NOT NULL,
    status            VARCHAR(20)  NOT NULL,
    created_at        TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP,
    created_by        UUID,
    updated_by        UUID,
    CONSTRAINT ck_organizations_type
        CHECK (organization_type IN ('FEDERATION', 'LEAGUE', 'ASSOCIATION', 'UNIVERSITY', 'CLUB', 'OTHER')),
    CONSTRAINT ck_organizations_status
        CHECK (status IN ('ACTIVE', 'INACTIVE'))
);

