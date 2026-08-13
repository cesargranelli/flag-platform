package br.com.flagplatform.venue.entity;

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
        name = "venues",
        uniqueConstraints = {
                @UniqueConstraint(
                        name = "uk_venues_organization_name",
                        columnNames = {"organization_id", "name"}
                )
        }
)
public class VenueEntity extends BaseEntity {

    @Column(name = "organization_id", nullable = false)
    private UUID organizationId;

    @Column(nullable = false, length = 150)
    private String name;

    @Column(length = 500)
    private String address;

    @Column(name = "maps_url", length = 500)
    private String mapsUrl;
}
