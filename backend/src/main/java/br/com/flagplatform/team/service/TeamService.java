package br.com.flagplatform.team.service;

import br.com.flagplatform.common.enums.OrganizationStatus;
import br.com.flagplatform.division.DivisionLookup;
import br.com.flagplatform.division.exception.DivisionCompetitionMismatchException;
import br.com.flagplatform.organization.OrganizationLookup;
import br.com.flagplatform.team.TeamInfo;
import br.com.flagplatform.team.TeamLookup;
import br.com.flagplatform.team.dto.request.CreateTeamRequest;
import br.com.flagplatform.team.dto.request.EnrollTeamRequest;
import br.com.flagplatform.team.dto.request.UpdateTeamRequest;
import br.com.flagplatform.team.dto.response.CompetitionTeamResponse;
import br.com.flagplatform.team.dto.response.TeamResponse;
import br.com.flagplatform.team.entity.CompetitionTeamEntity;
import br.com.flagplatform.team.entity.TeamEntity;
import br.com.flagplatform.team.exception.DuplicateTeamNameException;
import br.com.flagplatform.team.exception.TeamNotFoundException;
import br.com.flagplatform.team.mapper.TeamMapper;
import br.com.flagplatform.team.repository.CompetitionTeamRepository;
import br.com.flagplatform.team.repository.TeamRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@RequiredArgsConstructor
@Transactional(readOnly = true)
@Service
public class TeamService implements TeamLookup {

    private final TeamMapper mapper;
    private final TeamRepository teamRepository;
    private final CompetitionTeamRepository competitionTeamRepository;
    private final OrganizationLookup organizationLookup;
    private final DivisionLookup divisionLookup;

    @Transactional
    public TeamResponse create(UUID organizationId, CreateTeamRequest request, String currentUserEmail) {
        organizationLookup.assertExists(organizationId);

        if (teamRepository.existsByOrganizationIdAndNameIgnoreCase(
                organizationId, request.name())) {
            throw new DuplicateTeamNameException(request.name());
        }

        TeamEntity entity = mapper.toEntity(request);
        entity.setOrganizationId(organizationId);
        entity.setStatus(OrganizationStatus.ACTIVE);

        return toResponse(teamRepository.save(entity));
    }

    public List<TeamResponse> findByOrganizationId(UUID organizationId) {
        return toResponseList(teamRepository.findAllByOrganizationIdOrderByNameAsc(organizationId));
    }

    public TeamResponse findById(UUID id) {
        return toResponse(findEntityById(id));
    }

    @Transactional
    public TeamResponse update(UUID id, UpdateTeamRequest request, String currentUserEmail) {
        TeamEntity entity = findEntityById(id);

        organizationLookup.assertExists(request.organizationId());

        if (teamRepository.existsByOrganizationIdAndNameIgnoreCaseAndIdNot(
                request.organizationId(), request.name(), id)) {
            throw new DuplicateTeamNameException(request.name());
        }

        mapper.updateEntity(entity, request);

        return toResponse(teamRepository.save(entity));
    }

    @Transactional
    public void delete(UUID id, String currentUserEmail) {
        TeamEntity entity = findEntityById(id);
        teamRepository.delete(entity);
    }

    @Transactional
    public void deactivate(UUID id, String currentUserEmail) {
        TeamEntity entity = findEntityById(id);
        entity.setStatus(OrganizationStatus.INACTIVE);
        teamRepository.save(entity);
    }

    @Transactional
    public void reactivate(UUID id, String currentUserEmail) {
        TeamEntity entity = findEntityById(id);
        entity.setStatus(OrganizationStatus.ACTIVE);
        teamRepository.save(entity);
    }

    // --- CompetitionTeam endpoints ---

    @Transactional
    public CompetitionTeamResponse enrollInCompetition(
            UUID competitionId, UUID teamId, EnrollTeamRequest request, String currentUserEmail) {
        TeamEntity team = findEntityById(teamId);

        if (request != null && request.divisionId() != null) {
            divisionLookup.assertExists(request.divisionId());
            UUID divisionCompetition = divisionLookup.findCompetitionId(request.divisionId());
            if (!divisionCompetition.equals(competitionId)) {
                throw new DivisionCompetitionMismatchException();
            }
        }

        if (competitionTeamRepository.existsByCompetitionIdAndTeamId(competitionId, teamId)) {
            throw new IllegalArgumentException("Time já inscrito nesta competição");
        }

        CompetitionTeamEntity entity = new CompetitionTeamEntity();
        entity.setCompetitionId(competitionId);
        entity.setTeamId(teamId);
        entity.setDivisionId(request != null ? request.divisionId() : null);

        CompetitionTeamEntity saved = competitionTeamRepository.save(entity);

        return toCompetitionTeamResponse(saved);
    }

    @Transactional
    public void removeFromCompetition(UUID competitionId, UUID teamId) {
        CompetitionTeamEntity entity = competitionTeamRepository
                .findByCompetitionIdAndTeamId(competitionId, teamId)
                .orElseThrow(() -> new IllegalArgumentException(
                        "Inscrição do time " + teamId + " na competição " + competitionId + " não encontrada"));
        competitionTeamRepository.delete(entity);
    }

    public List<CompetitionTeamResponse> findByCompetitionId(UUID competitionId) {
        return competitionTeamRepository.findAllByCompetitionIdOrderByCreatedAtAsc(competitionId)
                .stream()
                .map(this::toCompetitionTeamResponse)
                .toList();
    }

    /**
     * Lista todos os times da plataforma com o nome da organização (clube).
     * Usado pelas telas de associação de times a campeonatos.
     */
    public List<TeamResponse> findAll() {
        return toResponseList(teamRepository.findAll());
    }

    private CompetitionTeamResponse toCompetitionTeamResponse(CompetitionTeamEntity ct) {
        TeamEntity team = teamRepository.findById(ct.getTeamId()).orElse(null);
        String teamName = team != null ? team.getName() : "Desconhecido";
        UUID organizationId = team != null ? team.getOrganizationId() : null;
        String organizationName = organizationId != null
                ? organizationLookup.findTradeNameById(organizationId)
                : null;
        return new CompetitionTeamResponse(
                ct.getId(),
                ct.getCompetitionId(),
                ct.getTeamId(),
                teamName,
                organizationId,
                organizationName,
                ct.getDivisionId(),
                ct.getCreatedAt());
    }

    /**
     * Resolve o nome da organização (clube) para enriquecer o TeamResponse.
     */
    private TeamResponse toResponse(TeamEntity entity) {
        TeamResponse base = mapper.toResponse(entity);
        String organizationName = entity.getOrganizationId() != null
                ? organizationLookup.findTradeNameById(entity.getOrganizationId())
                : null;
        return new TeamResponse(
                base.id(),
                base.organizationId(),
                organizationName,
                base.name(),
                base.shortName(),
                base.sportName(),
                base.logoUrl(),
                base.status(),
                base.createdAt(),
                base.updatedAt());
    }

    private List<TeamResponse> toResponseList(List<TeamEntity> entities) {
        return entities.stream().map(this::toResponse).toList();
    }

    // --- TeamLookup implementation ---

    private TeamEntity findEntityById(UUID id) {
        return teamRepository.findById(id)
                .orElseThrow(() -> new TeamNotFoundException(id));
    }

    @Override
    public void assertExists(UUID id) {
        findEntityById(id);
    }

    @Override
    public boolean existsById(UUID id) {
        return teamRepository.existsById(id);
    }

    @Override
    public List<TeamInfo> findTeamInfoByOrganizationId(UUID organizationId) {
        return teamRepository.findAllByOrganizationIdOrderByNameAsc(organizationId).stream()
                .map(team -> new TeamInfo(team.getId(), team.getName()))
                .toList();
    }

    @Override
    public TeamInfo findTeamInfoById(UUID id) {
        TeamEntity entity = findEntityById(id);
        return new TeamInfo(entity.getId(), entity.getName());
    }

}
