package br.com.flagplatform.team.entity;

import br.com.flagplatform.common.enums.OrganizationStatus;
import br.com.flagplatform.common.persistence.entity.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

import java.util.UUID;

@Getter
@Setter
@Entity
@Table(name = "team")
public class TeamEntity extends BaseEntity {

    @Column(name = "organization_id", nullable = false)
    private UUID organizationId;

    @Column(nullable = false, length = 255)
    private String name;

    @Column(name = "short_name", length = 50)
    private String shortName;

    @Column(name = "sport_name", length = 255)
    private String sportName;

    @Column(name = "logo_url", length = 500)
    private String logoUrl;

    @Column(nullable = false, length = 20)
    private OrganizationStatus status;
}
