package br.com.flagplatform.roster.dto.request;

import br.com.flagplatform.common.enums.RosterStatus;
import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public record RosterBatchItem(
        @NotNull
        UUID athleteId,

        RosterStatus status
) {
}
