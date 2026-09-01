-- V35: Status do atleta (ACTIVE/INACTIVE).
-- Exclusão lógica de atletas: registros existentes assumem ACTIVE.

ALTER TABLE platform.athletes
    ADD COLUMN status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE';