package br.com.flagplatform.category.entity;

import br.com.flagplatform.common.enums.AgeGroup;
import br.com.flagplatform.common.enums.Gender;
import br.com.flagplatform.common.persistence.entity.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@Entity
@Table(name = "categories")
public class CategoryEntity extends BaseEntity {

    @Column(name = "competition_id", nullable = false)
    private UUID competitionId;

    /** Rótulo derivado (modalidade + gênero + faixa) ou override do organizador. */
    @Column(length = 100)
    private String name;

    @Column(name = "modality_id", nullable = false)
    private UUID modalityId;

    @Column(nullable = false, length = 20)
    private Gender gender;

    @Column(name = "age_group", nullable = false, length = 20)
    private AgeGroup ageGroup;

    /** Marca de exclusão lógica; itens excluídos ficam com valor preenchido. */
    @Column(name = "deleted_at")
    private LocalDateTime deletedAt;

    public boolean isActive() {
        return deletedAt == null;
    }
}
