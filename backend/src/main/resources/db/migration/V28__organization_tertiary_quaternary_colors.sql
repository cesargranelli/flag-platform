-- V28: Organizações ganham cor terciária e quaternária.
-- O usuário pode definir até 4 cores da marca (primária, secundária,
-- terciária e quaternária). Colunas opcionais, hex RGB (#RRGGBB),
-- mesmo padrão de primary_color/secondary_color da V1.

ALTER TABLE platform.organizations
    ADD COLUMN IF NOT EXISTS tertiary_color VARCHAR(7),
    ADD COLUMN IF NOT EXISTS quaternary_color VARCHAR(7);
