-- V31: Atleta com até 3 posições (coleção) + apelido/número próprios no elenco.
-- Abordagem de BACKFILL/RESET (#367/#319): dados de dev são descartáveis; a
-- posição única legada é migrada para a nova tabela antes de dropar a coluna.

-- 1) Coleção de posições do atleta (até 3 por atleta).
CREATE TABLE platform.athlete_positions
(
    athlete_id UUID        NOT NULL,
    position   VARCHAR(20) NOT NULL,
    CONSTRAINT fk_athlete_positions_athlete
        FOREIGN KEY (athlete_id) REFERENCES platform.athletes (id)
);

-- Backfill: preserva os valores da posição única legada.
INSERT INTO platform.athlete_positions (athlete_id, position)
SELECT id, position
FROM platform.athletes
WHERE position IS NOT NULL;

-- Remove a coluna legada de posição única (dado migrado acima).
ALTER TABLE platform.athletes DROP COLUMN position;

-- 2) Apelido e número próprios por entrada de elenco (override por time).
ALTER TABLE platform.team_roster
    ADD COLUMN nickname VARCHAR(100),
    ADD COLUMN number   INTEGER;
