package br.com.flagplatform.conference.entity;

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
@Table(name = "conferences")
public class ConferenceEntity extends BaseEntity {

    @Column(name = "competition_id", nullable = false)
    private UUID competitionId;

    @Column(nullable = false, length = 100)
    private String name;
}