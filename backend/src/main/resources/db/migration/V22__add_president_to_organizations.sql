-- Presidente da organizacao: nome + CPF (obrigatorios).
-- O CNPJ (document/document_type) passa a ser opcional (a organizacao
-- pode nao ter CNPJ, usando o CPF do presidente como identificacao).
ALTER TABLE platform.organizations
    ADD COLUMN president_name VARCHAR(150),
    ADD COLUMN president_cpf  VARCHAR(14);

CREATE UNIQUE INDEX uk_organizations_president_cpf
    ON platform.organizations (president_cpf)
    WHERE president_cpf IS NOT NULL;
