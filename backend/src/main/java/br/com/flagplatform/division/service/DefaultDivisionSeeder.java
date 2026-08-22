package br.com.flagplatform.division.service;

import br.com.flagplatform.competition.CompetitionCreatedEvent;
import br.com.flagplatform.conference.ConferenceInfo;
import br.com.flagplatform.conference.ConferenceLookup;
import br.com.flagplatform.division.entity.DivisionEntity;
import br.com.flagplatform.division.repository.DivisionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.context.event.EventListener;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.UUID;

/**
 * Semeia a divisão padrão ("Divisão Geral") dentro da primeira conferência
 * do campeonato recém-criado (#258). Por convenção (sem coluna de flag),
 * a primeira conferência/primeira divisão é a padrão.
 */
@Component
@RequiredArgsConstructor
public class DefaultDivisionSeeder {

    public static final String DEFAULT_DIVISION_NAME = "Divisão Geral";

    private final DivisionRepository repository;
    private final ConferenceLookup conferenceLookup;

    @EventListener
    @Order(2)
    public void onCompetitionCreated(CompetitionCreatedEvent event) {
        UUID competitionId = event.competitionId();

        List<ConferenceInfo> conferences =
                conferenceLookup.findConferenceInfoByCompetitionId(competitionId);
        if (conferences.isEmpty()) {
            return;
        }
        UUID defaultConferenceId = conferences.get(0).id();

        if (repository.existsByCompetitionIdAndConferenceIdAndNameIgnoreCase(
                competitionId, defaultConferenceId, DEFAULT_DIVISION_NAME)) {
            return;
        }

        DivisionEntity entity = new DivisionEntity();
        entity.setCompetitionId(competitionId);
        entity.setConferenceId(defaultConferenceId);
        entity.setName(DEFAULT_DIVISION_NAME);
        repository.save(entity);
    }
}
