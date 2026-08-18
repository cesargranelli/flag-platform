package br.com.flagplatform.checkin.entity;

import br.com.flagplatform.common.enums.CheckInStatus;
import br.com.flagplatform.common.persistence.entity.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@Entity
@Table(
        name = "checkins",
        uniqueConstraints = {
                @UniqueConstraint(
                        name = "uk_checkins_game_athlete",
                        columnNames = {"game_id", "athlete_id"}
                )
        }
)
public class CheckInEntity extends BaseEntity {

    @Column(name = "game_id", nullable = false)
    private UUID gameId;

    @Column(name = "team_id", nullable = false)
    private UUID teamId;

    @Column(name = "athlete_id", nullable = false)
    private UUID athleteId;

    @Column(nullable = false)
    private CheckInStatus status;

    /** Numero do atleta apenas para esta partida (override; null = usar o oficial). */
    @Column(name = "match_number")
    private Integer matchNumber;

    @Column(name = "validated_by")
    private UUID validatedBy;

    @Column(name = "validated_at")
    private LocalDateTime validatedAt;
}
