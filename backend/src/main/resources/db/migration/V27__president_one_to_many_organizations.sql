-- V27: Presidente 1:N Organizações.
-- Um mesmo presidente (CPF) pode presidir múltiplas organizações;
-- remove o índice único parcial criado na V22. A unicidade do CNPJ
-- da organização permanece.

DROP INDEX IF EXISTS platform.uk_organizations_president_cpf;
