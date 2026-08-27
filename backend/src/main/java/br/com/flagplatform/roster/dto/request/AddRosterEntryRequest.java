package br.com.flagplatform.roster.dto.request;

import br.com.flagplatform.common.enums.RosterStatus;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public record AddRosterEntryRequest(
        @NotNull
        UUID athleteId,

        RosterStatus status,

        @Size(max = 100)
        String nickname,

        Integer number
) {
}
