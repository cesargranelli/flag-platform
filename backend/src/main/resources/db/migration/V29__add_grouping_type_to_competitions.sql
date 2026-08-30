-- V29: Campeonatos ganham o tipo de agrupamento da estrutura.
-- Divisões e Grupos têm a mesma dinâmica; muda apenas o rótulo (#308).
-- Valores: DIVISIONS | GROUPS. Nulo = legado, tratado como DIVISIONS.

ALTER TABLE platform.competitions
    ADD COLUMN IF NOT EXISTS grouping_type VARCHAR(20);
