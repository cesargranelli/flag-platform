package br.com.flagplatform.round.entity;

import br.com.flagplatform.common.enums.RoundType;
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
        name = "rounds",
        uniqueConstraints = {
                @UniqueConstraint(
                        name = "uk_rounds_competition_number",
                        columnNames = {"competition_id", "number"}
                )
        }
)
public class RoundEntity extends BaseEntity {

    @Column(name = "competition_id", nullable = false)
    private UUID competitionId;

    @Column(nullable = false)
    private Integer number;

    @Column(length = 100)
    private String name;

    @Column(nullable = false)
    private RoundType type;
}
