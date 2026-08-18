package br.com.flagplatform.athlete.entity;

import br.com.flagplatform.common.enums.AthletePosition;
import br.com.flagplatform.common.persistence.entity.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "athletes")
public class AthleteEntity extends BaseEntity {

    @Column(nullable = false, length = 150)
    private String name;

    @Column(nullable = false, length = 14)
    private String cpf;

    @Column(length = 100)
    private String nickname;

    private AthletePosition position;

    private Integer number;

    @Column(name = "photo_url", length = 500)
    private String photoUrl;
}
