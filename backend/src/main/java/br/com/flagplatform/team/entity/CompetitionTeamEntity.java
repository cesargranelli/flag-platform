package br.com.flagplatform.team.entity;

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
        name = "competition_team",
        uniqueConstraints = {
                @UniqueConstraint(
                        name = "uk_competition_team",
                        columnNames = {"competition_id", "team_id"}
                )
        }
)
public class CompetitionTeamEntity extends BaseEntity {

    @Column(name = "competition_id", nullable = false)
    private UUID competitionId;

    @Column(name = "team_id", nullable = false)
    private UUID teamId;

    @Column(name = "division_id")
    private UUID divisionId;
}
