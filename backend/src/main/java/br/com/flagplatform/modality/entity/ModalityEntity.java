package br.com.flagplatform.modality.entity;

import br.com.flagplatform.common.enums.ContactType;
import br.com.flagplatform.common.persistence.entity.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "modalities")
public class ModalityEntity extends BaseEntity {

    @Column(nullable = false, length = 60)
    private String name;

    @Column(nullable = false, length = 10)
    private String format;

    @Column(name = "contact_type", nullable = false, length = 20)
    private ContactType contactType;

    @Column(name = "players_per_team", nullable = false)
    private Integer playersPerTeam;

    @Column(nullable = false)
    private Boolean active = true;
}
