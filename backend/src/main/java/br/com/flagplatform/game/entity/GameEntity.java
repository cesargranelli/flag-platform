package br.com.flagplatform.game.entity;

import br.com.flagplatform.common.enums.GameStatus;
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
        name = "games",
        uniqueConstraints = {
                @UniqueConstraint(
                        name = "uk_games_round_home_away",
                        columnNames = {"round_id", "home_team_id", "away_team_id"}
                )
        }
)
public class GameEntity extends BaseEntity {

    @Column(name = "round_id", nullable = false)
    private UUID roundId;

    @Column(name = "home_team_id", nullable = false)
    private UUID homeTeamId;

    @Column(name = "away_team_id", nullable = false)
    private UUID awayTeamId;

    @Column(name = "venue_id")
    private UUID venueId;

    @Column(name = "scheduled_at")
    private LocalDateTime scheduledAt;

    @Column(nullable = false)
    private GameStatus status;

    @Column(name = "home_score")
    private Integer homeScore;

    @Column(name = "away_score")
    private Integer awayScore;
}
