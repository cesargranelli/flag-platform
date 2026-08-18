-- Numeracao de partida por atleta no check-in.
-- Permite ao referee trocar o numero de um atleta apenas para uma partida,
-- sem alterar o numero oficial cadastrado (athletes.number).
ALTER TABLE platform.checkins
    ADD COLUMN match_number INTEGER;
