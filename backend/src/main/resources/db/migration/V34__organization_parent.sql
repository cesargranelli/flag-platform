-- V34: Hierarquia de organizações (ADR-006).
-- Associa organizações filhas (clube/universidade) a uma organização
-- mãe (federação/liga/associação) via parent_id (auto-referência).

ALTER TABLE platform.organizations
    ADD COLUMN IF NOT EXISTS parent_id UUID;

ALTER TABLE platform.organizations
    ADD CONSTRAINT fk_organizations_parent
        FOREIGN KEY (parent_id) REFERENCES platform.organizations (id);

CREATE INDEX IF NOT EXISTS idx_organizations_parent_id
    ON platform.organizations (parent_id);