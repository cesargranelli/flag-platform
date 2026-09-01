-- V36: Data de nascimento e gênero do atleta.
-- Ambos opcionais (atletas legados podem não ter essas informações).

ALTER TABLE platform.athletes
    ADD COLUMN birth_date DATE;

ALTER TABLE platform.athletes
    ADD COLUMN gender VARCHAR(20);
