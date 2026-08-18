-- Catalogo de modalidades do futebol americano/flag football.
-- Tabela de referencia: sem CRUD no MVP (apenas leitura via GET /api/v1/modalities).
-- O seed padrao e aplicado em tempo de execucao (ModalityDataSeeder) para nao
-- depender da ordem Flyway x ddl-auto do Hibernate.
CREATE TABLE platform.modalities
(
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name             VARCHAR(60)  NOT NULL,
    format           VARCHAR(10)  NOT NULL,
    contact_type     VARCHAR(20)  NOT NULL,
    players_per_team INTEGER      NOT NULL,
    active           BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at       TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMP,
    created_by       UUID,
    updated_by       UUID,
    CONSTRAINT uk_modalities_format
        UNIQUE (format),
    CONSTRAINT ck_modalities_contact_type
        CHECK (contact_type IN ('FLAG', 'FULL_PAD', 'BEACH')),
    CONSTRAINT ck_modalities_players_per_team
        CHECK (players_per_team > 0)
);
