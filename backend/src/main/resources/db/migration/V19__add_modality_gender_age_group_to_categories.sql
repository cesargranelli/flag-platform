-- Estrutura de categorias: modalidade + gênero + faixa etária.
-- O name passa a ser derivado (override opcional); a unicidade passa a ser
-- pela combinação (competition_id, modality_id, gender, age_group) entre ativos.
ALTER TABLE platform.categories
    ADD COLUMN modality_id UUID REFERENCES platform.modalities (id),
    ADD COLUMN gender      VARCHAR(20),
    ADD COLUMN age_group   VARCHAR(20);

ALTER TABLE platform.categories
    ALTER COLUMN name DROP NOT NULL;

-- A unicidade passa de (competition_id, name) para a combinação estruturada.
DROP INDEX IF EXISTS uk_categories_competition_name_active;

CREATE UNIQUE INDEX uk_categories_competition_combination_active
    ON platform.categories (competition_id, modality_id, gender, age_group)
    WHERE deleted_at IS NULL;

-- Índices para acelerar consultas por modalidade (ex.: filtrar catálogo).
CREATE INDEX idx_categories_modality
    ON platform.categories (modality_id)
    WHERE deleted_at IS NULL;
