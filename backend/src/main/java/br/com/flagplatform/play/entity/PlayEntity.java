package br.com.flagplatform.play.entity;

import br.com.flagplatform.common.persistence.entity.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

import java.util.UUID;

@Getter
@Setter
@Entity
@Table(name = "plays", schema = "platform")
public class PlayEntity extends BaseEntity {

    @Column(name = "game_id", nullable = false)
    private UUID gameId;

    @Column(name = "team_id", nullable = false)
    private UUID teamId;

    @Column(name = "player_name", nullable = false, length = 100)
    private String playerName;

    @Column(name = "receiver_name", length = 100)
    private String receiverName;

    @Enumerated(EnumType.STRING)
    @Column(name = "play_type", nullable = false, length = 30)
    private PlayType playType;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column
    private Integer yards = 0;

    @Column(length = 5)
    private String quarter;

    @Column(length = 10)
    private String time;

    @Column(name = "is_first_down")
    private Boolean isFirstDown = false;

    @Column(name = "is_touchdown")
    private Boolean isTouchdown = false;

    @Column(name = "is_turnover")
    private Boolean isTurnover = false;
}
