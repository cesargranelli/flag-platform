package br.com.flagplatform.roster.dto.request;

import jakarta.validation.constraints.NotEmpty;

import java.util.List;

public record RosterBatchRequest(
        @NotEmpty
        List<RosterBatchItem> athletes
) {
}
