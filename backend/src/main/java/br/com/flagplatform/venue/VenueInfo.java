package br.com.flagplatform.venue;

import java.util.UUID;

/**
 * Projeção pública de um campo para exibição nos detalhes de jogos.
 */
public record VenueInfo(UUID id, String name, String address, String mapsUrl) {
}
