package br.com.flagplatform.conference.service;

import br.com.flagplatform.competition.CompetitionCreatedEvent;
import br.com.flagplatform.conference.entity.ConferenceEntity;
import br.com.flagplatform.conference.repository.ConferenceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.context.event.EventListener;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import java.util.UUID;

/**
 * Semeia a conferência padrão ("Conferência Geral") quando um campeonato
 * é criado (#258). Sem coluna de flag: por convenção, a primeira
 * conferência do campeonato é a padrão.
 */
@Component
@RequiredArgsConstructor
public class DefaultConferenceSeeder {

    public static final String DEFAULT_CONFERENCE_NAME = "Conferência Geral";

    private final ConferenceRepository repository;

    @EventListener
    @Order(1)
    public void onCompetitionCreated(CompetitionCreatedEvent event) {
        UUID competitionId = event.competitionId();

        if (repository.existsByCompetitionIdAndNameIgnoreCase(competitionId, DEFAULT_CONFERENCE_NAME)) {
            return;
        }

        ConferenceEntity entity = new ConferenceEntity();
        entity.setCompetitionId(competitionId);
        entity.setName(DEFAULT_CONFERENCE_NAME);
        repository.save(entity);
    }
}
