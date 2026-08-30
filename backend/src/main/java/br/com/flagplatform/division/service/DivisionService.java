package br.com.flagplatform.division.service;

import br.com.flagplatform.competition.CompetitionLookup;
import br.com.flagplatform.conference.ConferenceLookup;
import br.com.flagplatform.division.DivisionInfo;
import br.com.flagplatform.division.DivisionLookup;
import br.com.flagplatform.division.dto.request.CreateDivisionRequest;
import br.com.flagplatform.division.dto.request.UpdateDivisionRequest;
import br.com.flagplatform.division.dto.response.DivisionResponse;
import br.com.flagplatform.division.entity.DivisionEntity;
import br.com.flagplatform.division.exception.ConferenceCompetitionMismatchException;
import br.com.flagplatform.division.exception.DivisionNotFoundException;
import br.com.flagplatform.division.exception.DuplicateDivisionNameException;
import br.com.flagplatform.division.mapper.DivisionMapper;
import br.com.flagplatform.division.repository.DivisionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@RequiredArgsConstructor
@Transactional(readOnly = true)
@Service
public class DivisionService implements DivisionLookup {

    private final DivisionMapper mapper;
    private final DivisionRepository repository;
    private final CompetitionLookup competitionLookup;
    private final ConferenceLookup conferenceLookup;

    @Transactional
    public DivisionResponse create(UUID competitionId, CreateDivisionRequest request, String currentUserEmail) {
        // V260: apenas o criador do campeonato (ou ADMIN) gerencia o campeonato.
        competitionLookup.assertManagedBy(competitionId, currentUserEmail);
        // Issue #305: estrutura só é editável com o campeonato em DRAFT.
        competitionLookup.assertEditable(competitionId);

        validateConference(request.conferenceId(), competitionId);
        ensureUniqueName(competitionId, request.conferenceId(), request.name(), null);

        return mapper.toResponse(repository.save(mapper.toEntity(competitionId, request)));
    }

    public List<DivisionResponse> findByCompetitionId(UUID competitionId) {
        return mapper.toResponseList(repository.findAllByCompetitionIdOrderByNameAsc(competitionId));
    }

    public DivisionResponse findById(UUID id) {
        return mapper.toResponse(findEntityById(id));
    }

    @Transactional
    public DivisionResponse update(UUID id, UpdateDivisionRequest request, String currentUserEmail) {
        DivisionEntity entity = findEntityById(id);

        competitionLookup.assertManagedBy(entity.getCompetitionId(), currentUserEmail);
        // Issue #305: estrutura só é editável com o campeonato em DRAFT.
        competitionLookup.assertEditable(entity.getCompetitionId());

        validateConference(request.conferenceId(), entity.getCompetitionId());
        ensureUniqueName(entity.getCompetitionId(), request.conferenceId(), request.name(), id);

        mapper.updateEntity(entity, request);

        return mapper.toResponse(repository.save(entity));
    }

    /**
     * A conferência, quando informada, deve existir e pertencer à mesma
     * competição da divisão.
     */
    private void validateConference(UUID conferenceId, UUID competitionId) {
        if (conferenceId == null) {
            return;
        }
        conferenceLookup.assertExists(conferenceId);
        UUID conferenceCompetition = conferenceLookup.findCompetitionId(conferenceId);
        if (!conferenceCompetition.equals(competitionId)) {
            throw new ConferenceCompetitionMismatchException();
        }
    }

    private void ensureUniqueName(UUID competitionId, UUID conferenceId, String name, UUID currentId) {
        boolean duplicate;
        if (conferenceId == null) {
            duplicate = currentId == null
                    ? repository.existsByCompetitionIdAndConferenceIdIsNullAndNameIgnoreCase(
                            competitionId, name)
                    : repository.existsByCompetitionIdAndConferenceIdIsNullAndNameIgnoreCaseAndIdNot(
                            competitionId, name, currentId);
        } else {
            duplicate = currentId == null
                    ? repository.existsByCompetitionIdAndConferenceIdAndNameIgnoreCase(
                            competitionId, conferenceId, name)
                    : repository.existsByCompetitionIdAndConferenceIdAndNameIgnoreCaseAndIdNot(
                            competitionId, conferenceId, name, currentId);
        }
        if (duplicate) {
            throw new DuplicateDivisionNameException(name);
        }
    }

    /**
     * Elimina a divisão. V260: apenas o criador do campeonato (ou ADMIN) gerencia
     * o campeonato; issue #305: estrutura só é alterável com o campeonato em DRAFT.
     */
    @Transactional
    public void delete(UUID id, String currentUserEmail) {
        DivisionEntity entity = findEntityById(id);

        competitionLookup.assertManagedBy(entity.getCompetitionId(), currentUserEmail);
        competitionLookup.assertEditable(entity.getCompetitionId());

        repository.delete(entity);
    }

    private DivisionEntity findEntityById(UUID id) {
        return repository.findById(id)
                .orElseThrow(() -> new DivisionNotFoundException(id));
    }

    @Override
    public void assertExists(UUID id) {
        findEntityById(id);
    }

    @Override
    public UUID findCompetitionId(UUID divisionId) {
        return findEntityById(divisionId).getCompetitionId();
    }

    @Override
    public List<DivisionInfo> findDivisionInfoByCompetitionId(UUID competitionId) {
        return repository.findAllByCompetitionIdOrderByNameAsc(competitionId).stream()
                .map(division -> new DivisionInfo(
                        division.getId(),
                        division.getCompetitionId(),
                        division.getConferenceId(),
                        division.getName()))
                .toList();
    }

}
