package br.com.flagplatform.competition.entity;

import br.com.flagplatform.common.enums.CompetitionStatus;
import br.com.flagplatform.common.enums.Gender;
import br.com.flagplatform.common.enums.AgeGroup;
import br.com.flagplatform.common.enums.GroupingType;
import br.com.flagplatform.common.enums.Modality;
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

    @Column(name = "modality", nullable = false, length = 20)
    private Modality modality;

    @Column(nullable = false, length = 20)
    private Gender gender;

    @Column(name = "age_group", nullable = false, length = 20)
    private AgeGroup ageGroup;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(length = 500)
    private String description;

    private LocalDate startDate;

    private LocalDate endDate;

    @Column(nullable = false)
    private CompetitionStatus status;

    // Issue #308: rótulo do agrupamento (DIVISIONS | GROUPS) — mesma
    // dinâmica de divisões, mudando apenas o label. Nulo = legado
    // (tratado como DIVISIONS).
    @Column(name = "grouping_type", length = 20)
    private GroupingType groupingType;

    @Column(nullable = false, length = 50)
    private String season;
}
