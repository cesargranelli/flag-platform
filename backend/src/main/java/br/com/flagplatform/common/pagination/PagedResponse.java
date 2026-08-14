package br.com.flagplatform.common.pagination;

import java.util.List;

/**
 * Resultado paginado de uma listagem.
 */
public record PagedResponse<T>(List<T> items, long total) {
}
