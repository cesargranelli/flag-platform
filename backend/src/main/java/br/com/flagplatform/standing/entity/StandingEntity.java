package br.com.flagplatform.standing.entity;

import br.com.flagplatform.common.persistence.entity.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.Getter;
import lombok.Setter;

import java.util.UUID;

@Getter
@Setter
@Entity
@Table(
        name = "standings",
        uniqueConstraints = {
                @UniqueConstraint(
                        name = "uk_standings_competition_team",
                        columnNames = {"competition_id", "team_id"}
                )
        }
)
public class StandingEntity extends BaseEntity {

    @Column(name = "competition_id", nullable = false)
    private UUID competitionId;

    @Column(name = "team_id", nullable = false)
    private UUID teamId;

    @Column(nullable = false)
    private Integer played;

    @Column(nullable = false)
    private Integer wins;

    @Column(nullable = false)
    private Integer draws;

    @Column(nullable = false)
    private Integer losses;

    @Column(name = "goals_for", nullable = false)
    private Integer goalsFor;

    @Column(name = "goals_against", nullable = false)
    private Integer goalsAgainst;

    @Column(nullable = false)
    private Integer points;
}
