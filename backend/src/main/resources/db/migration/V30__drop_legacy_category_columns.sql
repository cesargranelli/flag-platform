-- V30: limpeza defensiva das colunas category_id da era de categorias.
-- A V24/V25 já as removeram em schemas onde aplicaram; bancos que
-- preservaram a coluna (com NOT NULL) fazem INSERTs do JPA falharem,
-- pois a entidade não mapeia category_id (#315).
-- Bloco idempotente: só age quando a coluna ainda existe, removendo
-- antes as constraints que dependem dela.

DO $$
DECLARE
    t text;
BEGIN
    FOREACH t IN ARRAY ARRAY['conferences', 'divisions', 'rounds', 'standings', 'teams']
    LOOP
        IF EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema = 'platform'
              AND table_name = t
              AND column_name = 'category_id'
        ) THEN
            -- Remove constraints (FK/UNIQUE/CHECK) que referenciam a coluna.
            EXECUTE format(
                $f$
                DO $inner$
                DECLARE r record;
                BEGIN
                    FOR r IN
                        SELECT con.conname
                        FROM pg_constraint con
                        JOIN pg_class rel ON rel.oid = con.conrelid
                        JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
                        JOIN pg_attribute att ON att.attrelid = con.conrelid
                                             AND att.attnum = ANY (con.conkey)
                        WHERE nsp.nspname = 'platform'
                          AND rel.relname = %L
                          AND att.attname = 'category_id'
                    LOOP
                        EXECUTE format(
                            'ALTER TABLE platform.%I DROP CONSTRAINT IF EXISTS %I',
                            t, r.conname);
                    END LOOP;
                END $inner$;
                $f$,
                t
            );
            EXECUTE format('ALTER TABLE platform.%I DROP COLUMN IF EXISTS category_id', t);
        END IF;
    END LOOP;
END $$;
