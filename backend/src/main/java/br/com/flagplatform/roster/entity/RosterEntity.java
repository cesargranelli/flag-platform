package br.com.flagplatform.roster.entity;

import br.com.flagplatform.common.enums.RosterStatus;
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
        name = "roster",
        uniqueConstraints = {
                @UniqueConstraint(
                        name = "uk_roster_team_competition",
                        columnNames = {"team_id", "competition_id"}
                )
        }
)
public class RosterEntity extends BaseEntity {

    @Column(name = "team_id", nullable = false)
    private UUID teamId;

    @Column(name = "competition_id", nullable = false)
    private UUID competitionId;

    @Column(length = 255)
    private String name;

    @Column(nullable = false, length = 50)
    private String season;

    @Column(nullable = false, length = 20)
    private RosterStatus status;
}
