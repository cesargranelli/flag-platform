package br.com.flagplatform.conference.service;

import br.com.flagplatform.category.CategoryLookup;
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
    private final CategoryLookup categoryLookup;

    @Transactional
    public ConferenceResponse create(UUID categoryId, CreateConferenceRequest request) {
        categoryLookup.assertExists(categoryId);

        if (repository.existsByCategoryIdAndNameIgnoreCase(categoryId, request.name())) {
            throw new DuplicateConferenceNameException(request.name());
        }

        return mapper.toResponse(repository.save(mapper.toEntity(categoryId, request)));
    }

    public List<ConferenceResponse> findByCategoryId(UUID categoryId) {
        return mapper.toResponseList(repository.findAllByCategoryIdOrderByNameAsc(categoryId));
    }

    public ConferenceResponse findById(UUID id) {
        return mapper.toResponse(findEntityById(id));
    }

    @Transactional
    public ConferenceResponse update(UUID id, UpdateConferenceRequest request) {
        ConferenceEntity entity = findEntityById(id);

        if (repository.existsByCategoryIdAndNameIgnoreCaseAndIdNot(
                entity.getCategoryId(), request.name(), id)) {
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
    public UUID findCategoryId(UUID conferenceId) {
        return findEntityById(conferenceId).getCategoryId();
    }

    @Override
    public List<ConferenceInfo> findConferenceInfoByCategoryId(UUID categoryId) {
        return repository.findAllByCategoryIdOrderByNameAsc(categoryId).stream()
                .map(conference -> new ConferenceInfo(
                        conference.getId(), conference.getCategoryId(), conference.getName()))
                .toList();
    }

}