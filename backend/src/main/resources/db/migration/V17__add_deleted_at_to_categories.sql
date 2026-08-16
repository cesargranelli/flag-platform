-- Exclusão lógica (soft delete) de categorias: mantém o histórico.
-- A coluna deleted_at marca itens excluídos; listas e checks ignoram não-nulos.
ALTER TABLE platform.categories
    ADD COLUMN deleted_at TIMESTAMP;

-- A unicidade de nome passa a valer apenas entre itens ATIVOS, permitindo
-- recriar uma categoria com o mesmo nome após exclusão lógica.
ALTER TABLE platform.categories
    DROP CONSTRAINT uk_categories_competition_name;

CREATE UNIQUE INDEX uk_categories_competition_name_active
    ON platform.categories (competition_id, name)
    WHERE deleted_at IS NULL;

-- Índice parcial para acelerar consultas de itens ativos por campeonato.
CREATE INDEX idx_categories_competition_active
    ON platform.categories (competition_id)
    WHERE deleted_at IS NULL;
