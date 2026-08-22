package br.com.flagplatform.team.service;

import br.com.flagplatform.common.enums.DocumentType;
import br.com.flagplatform.common.exception.DuplicateDocumentException;
import br.com.flagplatform.common.exception.InvalidDocumentException;
import br.com.flagplatform.common.validation.DocumentValidator;
import br.com.flagplatform.competition.CompetitionLookup;
import br.com.flagplatform.division.DivisionLookup;
import br.com.flagplatform.division.exception.DivisionCompetitionMismatchException;
import br.com.flagplatform.organization.OrganizationLookup;
import br.com.flagplatform.team.TeamInfo;
import br.com.flagplatform.team.TeamLookup;
import br.com.flagplatform.team.dto.request.CreateTeamRequest;
import br.com.flagplatform.team.dto.request.UpdateTeamRequest;
import br.com.flagplatform.team.dto.response.TeamResponse;
import br.com.flagplatform.team.entity.TeamEntity;
import br.com.flagplatform.team.exception.DuplicateTeamRegistrationException;
import br.com.flagplatform.team.exception.DuplicateTeamNameException;
import br.com.flagplatform.team.exception.TeamNotFoundException;
import br.com.flagplatform.team.mapper.TeamMapper;
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
    private final TeamRepository repository;
    private final OrganizationLookup organizationLookup;
    private final DivisionLookup divisionLookup;
    private final CompetitionLookup competitionLookup;

    @Transactional
    public TeamResponse create(CreateTeamRequest request, String currentUserEmail) {
        // V260: apenas o criador do campeonato (ou ADMIN) gerencia o campeonato.
        competitionLookup.assertManagedBy(request.competitionId(), currentUserEmail);

        organizationLookup.assertExists(request.organizationId());
        validateDivision(request.divisionId(), request.competitionId());

        if (repository.existsByCompetitionIdAndOrganizationId(
                request.competitionId(), request.organizationId())) {
            throw new DuplicateTeamRegistrationException(request.organizationId(), request.competitionId());
        }

        if (request.name() != null && !request.name().isBlank()
                && repository.existsByCompetitionIdAndNameIgnoreCase(
                        request.competitionId(), request.name())) {
            throw new DuplicateTeamNameException(request.name());
        }

        validateDocument(request.document(), request.documentType(), null);

        return mapper.toResponse(repository.save(mapper.toEntity(request)));
    }

    public List<TeamResponse> findByCompetitionId(UUID competitionId) {
        return mapper.toResponseList(repository.findAllByCompetitionIdOrderByNameAsc(competitionId));
    }

    public TeamResponse findById(UUID id) {
        return mapper.toResponse(findEntityById(id));
    }

    @Transactional
    public TeamResponse update(UUID id, UpdateTeamRequest request, String currentUserEmail) {
        TeamEntity entity = findEntityById(id);

        // V260: valida o campeonato atual do time e, se houver transferência,
        // também o campeonato de destino.
        competitionLookup.assertManagedBy(entity.getCompetitionId(), currentUserEmail);
        if (!entity.getCompetitionId().equals(request.competitionId())) {
            competitionLookup.assertManagedBy(request.competitionId(), currentUserEmail);
        }

        organizationLookup.assertExists(request.organizationId());
        validateDivision(request.divisionId(), request.competitionId());

        boolean changingEnrollment = !entity.getCompetitionId().equals(request.competitionId())
                || !entity.getOrganizationId().equals(request.organizationId());
        if (changingEnrollment && repository.existsByCompetitionIdAndOrganizationId(
                request.competitionId(), request.organizationId())) {
            throw new DuplicateTeamRegistrationException(request.organizationId(), request.competitionId());
        }

        if (request.name() != null && !request.name().isBlank()
                && repository.existsByCompetitionIdAndNameIgnoreCaseAndIdNot(
                        request.competitionId(), request.name(), id)) {
            throw new DuplicateTeamNameException(request.name());
        }

        validateDocument(request.document(), request.documentType(), id);

        mapper.updateEntity(entity, request);

        return mapper.toResponse(repository.save(entity));
    }

    /**
     * A divisão, quando informada, deve existir e pertencer à mesma
     * competição do time.
     */
    private void validateDivision(UUID divisionId, UUID competitionId) {
        if (divisionId == null) {
            return;
        }
        divisionLookup.assertExists(divisionId);
        UUID divisionCompetition = divisionLookup.findCompetitionId(divisionId);
        if (!divisionCompetition.equals(competitionId)) {
            throw new DivisionCompetitionMismatchException();
        }
    }

    /**
     * Valida o documento do time: obrigatorio CNPJ do time ou CPF do
     * representante; formato valido; documento unico.
     */
    private void validateDocument(String document, DocumentType type, UUID currentId) {
        if (document == null || document.isBlank()) {
            throw new InvalidDocumentException("Informe o CNPJ do time ou o CPF do representante.");
        }
        if (type == null) {
            throw new InvalidDocumentException("Informe o tipo do documento (CNPJ ou CPF).");
        }
        if (!DocumentValidator.isValid(document, type)) {
            throw new InvalidDocumentException("Documento inválido: " + type.getCode());
        }
        String normalized = document.replaceAll("\\D", "");
        boolean duplicate = currentId == null
                ? repository.existsByDocument(normalized)
                : repository.existsByDocumentAndIdNot(normalized, currentId);
        if (duplicate) {
            throw new DuplicateDocumentException(normalized);
        }
    }

    private TeamEntity findEntityById(UUID id) {
        return repository.findById(id)
                .orElseThrow(() -> new TeamNotFoundException(id));
    }

    @Override
    public void assertExists(UUID id) {
        findEntityById(id);
    }

    @Override
    public boolean existsById(UUID id) {
        return repository.existsById(id);
    }

    @Override
    public List<UUID> findTeamIdsByCompetitionId(UUID competitionId) {
        return repository.findAllByCompetitionIdOrderByNameAsc(competitionId).stream()
                .map(TeamEntity::getId)
                .toList();
    }

    @Override
    public List<TeamInfo> findTeamInfoByCompetitionId(UUID competitionId) {
        return repository.findAllByCompetitionIdOrderByNameAsc(competitionId).stream()
                .map(team -> new TeamInfo(team.getId(), team.getName()))
                .toList();
    }

    @Override
    public TeamInfo findTeamInfoById(UUID id) {
        TeamEntity entity = findEntityById(id);
        return new TeamInfo(entity.getId(), entity.getName());
    }

    @Override
    public UUID findCompetitionIdByTeamId(UUID teamId) {
        return findEntityById(teamId).getCompetitionId();
    }

}
