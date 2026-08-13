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
                        name = "uk_rounds_category_number",
                        columnNames = {"category_id", "number"}
                )
        }
)
public class RoundEntity extends BaseEntity {

    @Column(name = "category_id", nullable = false)
    private UUID categoryId;

    @Column(nullable = false)
    private Integer number;

    @Column(length = 100)
    private String name;

    @Column(nullable = false)
    private RoundType type;
}
