-- Estrutura de temporada: conferências e divisões dentro de cada categoria.
-- Campeonato -> Categoria -> Conferência (opcional) -> Divisão (opcional) -> Time.
CREATE TABLE platform.conferences
(
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID         NOT NULL,
    name        VARCHAR(100) NOT NULL,
    created_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP,
    created_by  UUID,
    updated_by  UUID,
    CONSTRAINT fk_conferences_category
        FOREIGN KEY (category_id) REFERENCES platform.categories (id),
    CONSTRAINT uk_conferences_category_name
        UNIQUE (category_id, name)
);

CREATE TABLE platform.divisions
(
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id   UUID         NOT NULL,
    conference_id UUID,
    name          VARCHAR(100) NOT NULL,
    created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP,
    created_by    UUID,
    updated_by    UUID,
    CONSTRAINT fk_divisions_category
        FOREIGN KEY (category_id) REFERENCES platform.categories (id),
    CONSTRAINT fk_divisions_conference
        FOREIGN KEY (conference_id) REFERENCES platform.conferences (id)
);

-- Nome único dentro do pai (categoria + conferência). Conferência nula indica
-- divisão diretamente na categoria; COALESCE mantém a unicidade também nesse caso.
CREATE UNIQUE INDEX uk_divisions_category_conference_name
    ON platform.divisions (category_id, COALESCE(conference_id, '00000000-0000-0000-0000-000000000000'), name);

-- Time se vincula à divisão (opcional); a cadeia divisão -> conferência -> categoria
-- é preservada e validada em serviço.
ALTER TABLE platform.teams
    ADD COLUMN division_id UUID REFERENCES platform.divisions (id);