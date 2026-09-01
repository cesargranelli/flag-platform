package br.com.flagplatform.athlete.entity;

import br.com.flagplatform.common.enums.AthletePosition;
import br.com.flagplatform.common.enums.AthleteStatus;
import br.com.flagplatform.common.enums.Gender;
import br.com.flagplatform.common.persistence.entity.BaseEntity;
import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

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

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "athlete_positions", joinColumns = @JoinColumn(name = "athlete_id"))
    @Column(name = "position")
    private List<AthletePosition> positions = new ArrayList<>();

    private Integer number;

    @Column(name = "photo_url", length = 500)
    private String photoUrl;

    @Column(nullable = false, length = 20)
    private AthleteStatus status;

    @Column(name = "birth_date")
    private LocalDate birthDate;

    @Column(length = 20)
    private Gender gender;
}
