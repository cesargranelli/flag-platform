package br.com.flagplatform.conference.service;

import br.com.flagplatform.competition.CompetitionLookup;
import br.com.flagplatform.conference.ConferenceInfo;
import br.com.flagplatform.conference.ConferenceLookup;
import br.com.flagplatform.conference.dto.request.CreateConferenceRequest;
import br.com.flagplatform.conference.dto.request.UpdateConferenceRequest;
import br.com.flagplatform.conference.dto.response.ConferenceResponse;
import br.com.flagplatform.conference.entity.ConferenceEntity;
import br.com.flagplatform.conference.exception.ConferenceNotFoundException;
import br.com.flagplatform.conference.exception.DuplicateConferenceNameException;
import br.com.flagplatform.conference.mapper.ConferenceMapper;
import br.com.flagplatform.conference.repository.ConferenceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@RequiredArgsConstructor
@Transactional(readOnly = true)
@Service
public class ConferenceService implements ConferenceLookup {

    private final ConferenceMapper mapper;
    private final ConferenceRepository repository;
    private final CompetitionLookup competitionLookup;

    @Transactional
    public ConferenceResponse create(UUID competitionId, CreateConferenceRequest request) {
        competitionLookup.assertExists(competitionId);

        if (repository.existsByCompetitionIdAndNameIgnoreCase(competitionId, request.name())) {
            throw new DuplicateConferenceNameException(request.name());
        }

        return mapper.toResponse(repository.save(mapper.toEntity(competitionId, request)));
    }

    public List<ConferenceResponse> findByCompetitionId(UUID competitionId) {
        return mapper.toResponseList(repository.findAllByCompetitionIdOrderByNameAsc(competitionId));
    }

    public ConferenceResponse findById(UUID id) {
        return mapper.toResponse(findEntityById(id));
    }

    @Transactional
    public ConferenceResponse update(UUID id, UpdateConferenceRequest request) {
        ConferenceEntity entity = findEntityById(id);

        if (repository.existsByCompetitionIdAndNameIgnoreCaseAndIdNot(
                entity.getCompetitionId(), request.name(), id)) {
            throw new DuplicateConferenceNameException(request.name());
        }

        mapper.updateEntity(entity, request);

        return mapper.toResponse(repository.save(entity));
    }

    private ConferenceEntity findEntityById(UUID id) {
        return repository.findById(id)
                .orElseThrow(() -> new ConferenceNotFoundException(id));
    }

    @Override
    public void assertExists(UUID id) {
        findEntityById(id);
    }

    @Override
    public UUID findCompetitionId(UUID conferenceId) {
        return findEntityById(conferenceId).getCompetitionId();
    }

    @Override
    public List<ConferenceInfo> findConferenceInfoByCompetitionId(UUID competitionId) {
        return repository.findAllByCompetitionIdOrderByNameAsc(competitionId).stream()
                .map(conference -> new ConferenceInfo(
                        conference.getId(), conference.getCompetitionId(), conference.getName()))
                .toList();
    }

}
