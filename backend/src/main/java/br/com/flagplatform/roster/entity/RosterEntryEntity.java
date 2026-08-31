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
        name = "team_roster",
        uniqueConstraints = {
                @UniqueConstraint(
                        name = "uk_team_roster_roster_athlete",
                        columnNames = {"roster_id", "athlete_id"}
                )
        }
)
public class RosterEntryEntity extends BaseEntity {

    @Column(name = "roster_id", nullable = false)
    private UUID rosterId;

    @Column(name = "athlete_id", nullable = false)
    private UUID athleteId;

    @Column(nullable = false)
    private RosterStatus status;

    @Column(length = 100)
    private String nickname;

    private Integer number;
}
