package br.com.flagplatform.team.entity;

import br.com.flagplatform.common.enums.DocumentType;
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
        name = "teams",
        uniqueConstraints = {
                @UniqueConstraint(
                        name = "uk_teams_competition_organization",
                        columnNames = {"competition_id", "organization_id"}
                )
        }
)
public class TeamEntity extends BaseEntity {

    @Column(name = "organization_id", nullable = false)
    private UUID organizationId;

    @Column(name = "competition_id", nullable = false)
    private UUID competitionId;

    /** Divisão opcional; a cadeia divisão -> conferência -> categoria é validada em serviço. */
    @Column(name = "division_id")
    private UUID divisionId;

    @Column(nullable = false, length = 150)
    private String name;

    @Column(name = "short_name", length = 20)
    private String shortName;

    @Column(length = 20)
    private String document;

    @Column(name = "document_type", length = 10)
    private DocumentType documentType;

    @Column(name = "logo_url", length = 500)
    private String logoUrl;
}
