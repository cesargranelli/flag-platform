-- Documentos de identificacao: organizacao e time aceitam CNPJ ou CPF
-- (obrigatorio um dos dois); atleta exige CPF.
ALTER TABLE platform.organizations
    ADD COLUMN document      VARCHAR(20),
    ADD COLUMN document_type VARCHAR(10);

ALTER TABLE platform.teams
    ADD COLUMN document      VARCHAR(20),
    ADD COLUMN document_type VARCHAR(10);

ALTER TABLE platform.athletes
    ADD COLUMN cpf VARCHAR(14);

-- Unicidade por documento (CNPJ/CPF sao unicos).
CREATE UNIQUE INDEX uk_organizations_document
    ON platform.organizations (document)
    WHERE document IS NOT NULL;

CREATE UNIQUE INDEX uk_teams_document
    ON platform.teams (document)
    WHERE document IS NOT NULL;

CREATE UNIQUE INDEX uk_athletes_cpf
    ON platform.athletes (cpf)
    WHERE cpf IS NOT NULL;
