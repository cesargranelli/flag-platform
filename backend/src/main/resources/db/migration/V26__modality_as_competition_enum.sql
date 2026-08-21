-- V26: Modalidade passa a ser enum da competicao (Opcao A).
-- Modalidades sao formatos fixos do esporte; o catalogo platform.modalities
-- (tabela + seed em runtime) e substituido pelo enum Modality persistido
-- na propria competicao, a exemplo de gender e age_group.

ALTER TABLE platform.competitions
    ADD COLUMN modality VARCHAR(20);

-- Backfill preservando valores existentes: mapeia (name, format) do catalogo
-- para o codigo do enum correspondente.
UPDATE platform.competitions c
SET modality = CASE
    WHEN m.name = 'Flag Football' AND m.format = '5x5'   THEN 'FLAG_5X5'
    WHEN m.name = 'Flag Football' AND m.format = '8x8'   THEN 'FLAG_8X8'
    WHEN m.name = 'Flag Football' AND m.format = '9x9'   THEN 'FLAG_9X9'
    WHEN m.name = 'Full Pads'     AND m.format = '11x11' THEN 'FULL_PADS_11X11'
END
FROM platform.modalities m
WHERE c.modality_id = m.id;

-- Fallback: competicoes criadas via API entre V24 e V26 podem ter
-- modality_id NULL (a V24 adicionou a coluna sem NOT NULL e os DTOs da
-- epoca nao expunham o campo). Como competicao sem modalidade e dado
-- incompleto, aplica o formato padrao do primeiro cliente (Flag 5x5).
UPDATE platform.competitions
SET modality = 'FLAG_5X5'
WHERE modality IS NULL;

-- Remove a referencia ao catalogo; modalidade passa a ser obrigatoria.
ALTER TABLE platform.competitions
    DROP CONSTRAINT fk_competitions_modality,
    DROP COLUMN modality_id,
    ALTER COLUMN modality SET NOT NULL;

-- Catalogo de modalidades deixa de existir.
DROP TABLE platform.modalities;
