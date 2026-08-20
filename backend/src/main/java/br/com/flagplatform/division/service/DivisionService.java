package br.com.flagplatform.division.service;

import br.com.flagplatform.category.CategoryLookup;
import br.com.flagplatform.conference.ConferenceLookup;
import br.com.flagplatform.division.DivisionInfo;
import br.com.flagplatform.division.DivisionLookup;
import br.com.flagplatform.division.dto.request.CreateDivisionRequest;
import br.com.flagplatform.division.dto.request.UpdateDivisionRequest;
import br.com.flagplatform.division.dto.response.DivisionResponse;
import br.com.flagplatform.division.entity.DivisionEntity;
import br.com.flagplatform.division.exception.ConferenceCategoryMismatchException;
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
    private final CategoryLookup categoryLookup;
    private final ConferenceLookup conferenceLookup;

    @Transactional
    public DivisionResponse create(UUID categoryId, CreateDivisionRequest request) {
        categoryLookup.assertExists(categoryId);
        validateConference(request.conferenceId(), categoryId);
        ensureUniqueName(categoryId, request.conferenceId(), request.name(), null);

        return mapper.toResponse(repository.save(mapper.toEntity(categoryId, request)));
    }

    public List<DivisionResponse> findByCategoryId(UUID categoryId) {
        return mapper.toResponseList(repository.findAllByCategoryIdOrderByNameAsc(categoryId));
    }

    public DivisionResponse findById(UUID id) {
        return mapper.toResponse(findEntityById(id));
    }

    @Transactional
    public DivisionResponse update(UUID id, UpdateDivisionRequest request) {
        DivisionEntity entity = findEntityById(id);
        validateConference(request.conferenceId(), entity.getCategoryId());
        ensureUniqueName(entity.getCategoryId(), request.conferenceId(), request.name(), id);

        mapper.updateEntity(entity, request);

        return mapper.toResponse(repository.save(entity));
    }

    /**
     * A conferência, quando informada, deve existir e pertencer à mesma
     * categoria da divisão.
     */
    private void validateConference(UUID conferenceId, UUID categoryId) {
        if (conferenceId == null) {
            return;
        }
        conferenceLookup.assertExists(conferenceId);
        UUID conferenceCategory = conferenceLookup.findCategoryId(conferenceId);
        if (!conferenceCategory.equals(categoryId)) {
            throw new ConferenceCategoryMismatchException();
        }
    }

    private void ensureUniqueName(UUID categoryId, UUID conferenceId, String name, UUID currentId) {
        boolean duplicate;
        if (conferenceId == null) {
            duplicate = currentId == null
                    ? repository.existsByCategoryIdAndConferenceIdIsNullAndNameIgnoreCase(
                            categoryId, name)
                    : repository.existsByCategoryIdAndConferenceIdIsNullAndNameIgnoreCaseAndIdNot(
                            categoryId, name, currentId);
        } else {
            duplicate = currentId == null
                    ? repository.existsByCategoryIdAndConferenceIdAndNameIgnoreCase(
                            categoryId, conferenceId, name)
                    : repository.existsByCategoryIdAndConferenceIdAndNameIgnoreCaseAndIdNot(
                            categoryId, conferenceId, name, currentId);
        }
        if (duplicate) {
            throw new DuplicateDivisionNameException(name);
        }
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
    public UUID findCategoryId(UUID divisionId) {
        return findEntityById(divisionId).getCategoryId();
    }

    @Override
    public List<DivisionInfo> findDivisionInfoByCategoryId(UUID categoryId) {
        return repository.findAllByCategoryIdOrderByNameAsc(categoryId).stream()
                .map(division -> new DivisionInfo(
                        division.getId(),
                        division.getCategoryId(),
                        division.getConferenceId(),
                        division.getName()))
                .toList();
    }

}