package br.com.flagplatform.checkin.dto.request;

import br.com.flagplatform.common.enums.CheckInStatus;
import jakarta.validation.constraints.NotNull;

public record CheckInStatusRequest(
        @NotNull
        CheckInStatus status
) {
}
