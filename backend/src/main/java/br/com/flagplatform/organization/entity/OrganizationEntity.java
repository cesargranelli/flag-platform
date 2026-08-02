package br.com.flagplatform.organization.entity;

import br.com.flagplatform.common.enums.OrganizationStatus;
import br.com.flagplatform.common.enums.OrganizationType;
import br.com.flagplatform.common.persistence.entity.BaseEntity;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(
        name = "organizations",
        uniqueConstraints = {
                @UniqueConstraint(
                        name = "uk_organizations_trade_name",
                        columnNames = "trade_name"
                )
        }
)
public class OrganizationEntity extends BaseEntity {
    private String legalName;
    private String tradeName;
    private String abbreviation;
    private OrganizationType organizationType;
    private String email;
    private String phone;
    private String website;
    private String instagram;
    private String country;
    private String state;
    private String city;
    private String logoUrl;
    private String primaryColor;
    private String secondaryColor;
    private String timezone;
    private String locale;
    private OrganizationStatus status;
}
