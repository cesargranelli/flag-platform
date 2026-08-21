package br.com.flagplatform.division.entity;

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
@Table(name = "divisions")
public class DivisionEntity extends BaseEntity {

    @Column(name = "competition_id", nullable = false)
    private UUID competitionId;

    /** Conferência opcional; nula indica divisão diretamente no campeonato. */
    @Column(name = "conference_id")
    private UUID conferenceId;

    @Column(nullable = false, length = 100)
    private String name;
}