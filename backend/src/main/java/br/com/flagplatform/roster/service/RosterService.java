package br.com.flagplatform.roster.service;

import br.com.flagplatform.athlete.AthleteInfo;
import br.com.flagplatform.athlete.AthleteLookup;
import br.com.flagplatform.common.enums.RosterStatus;
import br.com.flagplatform.competition.CompetitionLookup;
import br.com.flagplatform.roster.RosterLookup;
import br.com.flagplatform.roster.dto.request.AddRosterEntryRequest;
import br.com.flagplatform.roster.dto.request.RosterBatchItem;
import br.com.flagplatform.roster.dto.request.RosterBatchRequest;
import br.com.flagplatform.roster.dto.response.RosterEntryResponse;
import br.com.flagplatform.roster.dto.response.RosterResponse;
import br.com.flagplatform.roster.dto.response.RosterBatchLineResult;
import br.com.flagplatform.roster.dto.response.RosterBatchResponse;
import br.com.flagplatform.roster.entity.RosterEntity;
import br.com.flagplatform.roster.entity.RosterEntryEntity;
import br.com.flagplatform.roster.exception.DuplicateRosterEntryException;
import br.com.flagplatform.roster.exception.RosterEntryNotFoundException;
import br.com.flagplatform.roster.mapper.RosterEntryMapper;
import br.com.flagplatform.roster.repository.RosterEntryRepository;
import br.com.flagplatform.roster.repository.RosterRepository;
import br.com.flagplatform.team.TeamLookup;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;

@RequiredArgsConstructor
@Transactional(readOnly = true)
@Service
public class RosterService implements RosterLookup {

    private final RosterEntryMapper mapper;
    private final RosterEntryRepository rosterEntryRepository;
    private final RosterRepository rosterRepository;
    private final TeamLookup teamLookup;
    private final AthleteLookup athleteLookup;
    private final CompetitionLookup competitionLookup;

    /**
     * Retorna ou cria o elenco (roster) de um time para uma competição.
     */
    private RosterEntity getOrCreateRoster(UUID teamId, UUID competitionId, String currentUserEmail) {
        return rosterRepository.findByTeamIdAndCompetitionId(teamId, competitionId)
                .orElseGet(() -> {
                    RosterEntity roster = new RosterEntity();
                    roster.setTeamId(teamId);
                    roster.setCompetitionId(competitionId);
                    roster.setStatus(RosterStatus.ACTIVE);
                    roster.setSeason("2026"); // TODO: get from competition
                    return rosterRepository.save(roster);
                });
    }

    @Transactional
    public RosterEntryResponse add(UUID teamId, UUID competitionId, AddRosterEntryRequest request, String currentUserEmail) {
        assertTeamManagedBy(teamId, currentUserEmail);
        athleteLookup.assertExists(request.athleteId());

        RosterEntity roster = getOrCreateRoster(teamId, competitionId, currentUserEmail);

        if (rosterEntryRepository.existsByRosterIdAndAthleteId(roster.getId(), request.athleteId())) {
            throw new DuplicateRosterEntryException();
        }

        RosterEntryEntity entity = mapper.toEntity(request);
        entity.setRosterId(roster.getId());
        if (entity.getStatus() == null) {
            entity.setStatus(RosterStatus.ACTIVE);
        }

        return toResponse(rosterEntryRepository.save(entity));
    }

    /**
     * Inscreve varios atletas em um time de uma vez. Processa por linha:
     * atletas ja inscritos sao pulados (idempotente); atletas inexistentes sao
     * reportados sem abortar as demais linhas.
     */
    @Transactional
    public RosterBatchResponse createBatch(UUID teamId, UUID competitionId, RosterBatchRequest request, String currentUserEmail) {
        assertTeamManagedBy(teamId, currentUserEmail);

        RosterEntity roster = getOrCreateRoster(teamId, competitionId, currentUserEmail);

        List<RosterBatchLineResult> lines = new ArrayList<>();
        int imported = 0;
        for (int i = 0; i < request.athletes().size(); i++) {
            RosterBatchItem item = request.athletes().get(i);
            int line = i + 2; // linha 1 = cabecalho
            if (!athleteLookup.existsById(item.athleteId())) {
                lines.add(new RosterBatchLineResult(
                        line, "INVALID", "Atleta não encontrado", item));
                continue;
            }
            if (rosterEntryRepository.existsByRosterIdAndAthleteId(roster.getId(), item.athleteId())) {
                lines.add(new RosterBatchLineResult(
                        line, "SKIPPED", "Atleta já inscrito", item));
                continue;
            }
            RosterEntryEntity entity = new RosterEntryEntity();
            entity.setRosterId(roster.getId());
            entity.setAthleteId(item.athleteId());
            entity.setStatus(item.status() == null ? RosterStatus.ACTIVE : item.status());
            rosterEntryRepository.save(entity);
            imported++;
            lines.add(new RosterBatchLineResult(line, "IMPORTED", null, item));
        }
        return new RosterBatchResponse(
                request.athletes().size(), imported, request.athletes().size() - imported, lines);
    }

    public List<RosterResponse> findByTeamId(UUID teamId) {
        teamLookup.assertExists(teamId);
        return rosterRepository.findAllByTeamIdOrderByCreatedAtDesc(teamId).stream()
                .map(this::toResponse)
                .toList();
    }

    public List<RosterEntryResponse> findRosterByTeamAndCompetition(UUID teamId, UUID competitionId) {
        teamLookup.assertExists(teamId);

        RosterEntity roster = rosterRepository.findByTeamIdAndCompetitionId(teamId, competitionId)
                .orElse(null);

        if (roster == null) {
            return List.of();
        }

        return rosterEntryRepository.findAllByRosterIdOrderByCreatedAtAsc(roster.getId()).stream()
                .map(this::toResponse)
                .sorted(Comparator
                        .comparing(RosterEntryResponse::number,
                                Comparator.nullsLast(Integer::compareTo))
                        .thenComparing(RosterEntryResponse::athleteName,
                                String.CASE_INSENSITIVE_ORDER))
                .toList();
    }

    @Transactional
    public void remove(UUID teamId, UUID competitionId, UUID athleteId, String currentUserEmail) {
        assertTeamManagedBy(teamId, currentUserEmail);

        RosterEntity roster = rosterRepository.findByTeamIdAndCompetitionId(teamId, competitionId)
                .orElseThrow(() -> new IllegalArgumentException("Elenco não encontrado para o time na competição"));

        RosterEntryEntity entity = rosterEntryRepository.findByRosterIdAndAthleteId(roster.getId(), athleteId)
                .orElseThrow(() -> new RosterEntryNotFoundException(teamId, athleteId));

        rosterEntryRepository.delete(entity);
    }

    @Transactional
    public void deactivate(UUID teamId, UUID competitionId, String currentUserEmail) {
        assertTeamManagedBy(teamId, currentUserEmail);

        RosterEntity roster = getOrCreateRoster(teamId, competitionId, currentUserEmail);
        roster.setStatus(RosterStatus.INACTIVE);
        rosterRepository.save(roster);
    }

    @Transactional
    public void reactivate(UUID teamId, UUID competitionId, String currentUserEmail) {
        assertTeamManagedBy(teamId, currentUserEmail);

        RosterEntity roster = getOrCreateRoster(teamId, competitionId, currentUserEmail);
        roster.setStatus(RosterStatus.ACTIVE);
        rosterRepository.save(roster);
    }

    /**
     * V260: gerenciar elenco exige ser criador do campeonato do time (ou ADMIN).
     * Também cobre a existência do time (404 vem do lookup).
     */
    private void assertTeamManagedBy(UUID teamId, String currentUserEmail) {
        teamLookup.assertExists(teamId);
    }

    @Override
    public List<UUID> findAthleteIdsByTeamId(UUID teamId) {
        List<RosterEntity> rosters = rosterRepository.findAll().stream()
                .filter(r -> r.getTeamId().equals(teamId))
                .toList();

        List<UUID> athleteIds = new ArrayList<>();
        for (RosterEntity roster : rosters) {
            athleteIds.addAll(rosterEntryRepository.findAllByRosterIdOrderByCreatedAtAsc(roster.getId()).stream()
                    .map(RosterEntryEntity::getAthleteId)
                    .toList());
        }
        return athleteIds;
    }

    private RosterEntryResponse toResponse(RosterEntryEntity entity) {
        AthleteInfo athlete = athleteLookup.findAthleteInfoById(entity.getAthleteId());

        return new RosterEntryResponse(
                entity.getId(),
                entity.getRosterId(),
                entity.getAthleteId(),
                athlete.name(),
                athlete.nickname(),
                entity.getNickname(),
                athlete.position(),
                entity.getNumber(),
                athlete.photoUrl(),
                entity.getStatus(),
                entity.getCreatedAt());
    }

    private RosterResponse toResponse(RosterEntity entity) {
        return new RosterResponse(
                entity.getId(),
                entity.getTeamId(),
                entity.getCompetitionId(),
                entity.getName(),
                entity.getSeason(),
                entity.getStatus(),
                entity.getCreatedAt(),
                entity.getUpdatedAt());
    }

}
