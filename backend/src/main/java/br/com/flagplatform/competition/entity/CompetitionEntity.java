package br.com.flagplatform.competition.entity;

import br.com.flagplatform.common.enums.CompetitionStatus;
import br.com.flagplatform.common.persistence.entity.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;
import java.util.UUID;

@Getter
@Setter
@Entity
@Table(
        name = "competitions",
        uniqueConstraints = {
                @UniqueConstraint(
                        name = "uk_competitions_organization_name",
                        columnNames = {"organization_id", "name"}
                )
        }
)
public class CompetitionEntity extends BaseEntity {

    @Column(name = "organization_id", nullable = false)
    private UUID organizationId;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(length = 500)
    private String description;

    private LocalDate startDate;

    private LocalDate endDate;

    @Column(nullable = false)
    private CompetitionStatus status;
}
