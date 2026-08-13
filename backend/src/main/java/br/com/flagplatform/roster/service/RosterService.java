package br.com.flagplatform.roster.service;

import br.com.flagplatform.athlete.AthleteInfo;
import br.com.flagplatform.athlete.AthleteLookup;
import br.com.flagplatform.common.enums.RosterStatus;
import br.com.flagplatform.roster.dto.request.AddRosterEntryRequest;
import br.com.flagplatform.roster.dto.response.RosterEntryResponse;
import br.com.flagplatform.roster.entity.RosterEntryEntity;
import br.com.flagplatform.roster.exception.DuplicateRosterEntryException;
import br.com.flagplatform.roster.exception.RosterEntryNotFoundException;
import br.com.flagplatform.roster.mapper.RosterEntryMapper;
import br.com.flagplatform.roster.repository.RosterEntryRepository;
import br.com.flagplatform.team.TeamLookup;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Comparator;
import java.util.List;
import java.util.UUID;

@RequiredArgsConstructor
@Transactional(readOnly = true)
@Service
public class RosterService {

    private final RosterEntryMapper mapper;
    private final RosterEntryRepository repository;
    private final TeamLookup teamLookup;
    private final AthleteLookup athleteLookup;

    @Transactional
    public RosterEntryResponse add(UUID teamId, AddRosterEntryRequest request) {
        teamLookup.assertExists(teamId);
        athleteLookup.assertExists(request.athleteId());

        if (repository.existsByTeamIdAndAthleteId(teamId, request.athleteId())) {
            throw new DuplicateRosterEntryException();
        }

        RosterEntryEntity entity = mapper.toEntity(request);
        entity.setTeamId(teamId);
        if (entity.getStatus() == null) {
            entity.setStatus(RosterStatus.ACTIVE);
        }

        return toResponse(repository.save(entity));
    }

    public List<RosterEntryResponse> findRosterByTeam(UUID teamId) {
        teamLookup.assertExists(teamId);

        return repository.findAllByTeamIdOrderByCreatedAtAsc(teamId).stream()
                .map(this::toResponse)
                .sorted(Comparator.comparing(RosterEntryResponse::athleteName,
                        String.CASE_INSENSITIVE_ORDER))
                .toList();
    }

    @Transactional
    public void remove(UUID teamId, UUID athleteId) {
        RosterEntryEntity entity = repository.findByTeamIdAndAthleteId(teamId, athleteId)
                .orElseThrow(() -> new RosterEntryNotFoundException(teamId, athleteId));

        repository.delete(entity);
    }

    private RosterEntryResponse toResponse(RosterEntryEntity entity) {
        AthleteInfo athlete = athleteLookup.findAthleteInfoById(entity.getAthleteId());

        return new RosterEntryResponse(
                entity.getId(),
                entity.getTeamId(),
                entity.getAthleteId(),
                athlete.name(),
                athlete.nickname(),
                athlete.position(),
                athlete.number(),
                athlete.photoUrl(),
                entity.getStatus(),
                entity.getCreatedAt());
    }

}
