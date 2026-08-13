package br.com.flagplatform.round.service;

import br.com.flagplatform.category.CategoryLookup;
import br.com.flagplatform.round.RoundLookup;
import br.com.flagplatform.round.dto.request.CreateRoundRequest;
import br.com.flagplatform.round.dto.request.UpdateRoundRequest;
import br.com.flagplatform.round.dto.response.RoundResponse;
import br.com.flagplatform.round.entity.RoundEntity;
import br.com.flagplatform.round.exception.DuplicateRoundNumberException;
import br.com.flagplatform.round.exception.RoundNotFoundException;
import br.com.flagplatform.round.mapper.RoundMapper;
import br.com.flagplatform.round.repository.RoundRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@RequiredArgsConstructor
@Transactional(readOnly = true)
@Service
public class RoundService implements RoundLookup {

    private final RoundMapper mapper;
    private final RoundRepository repository;
    private final CategoryLookup categoryLookup;

    @Transactional
    public RoundResponse create(CreateRoundRequest request) {
        categoryLookup.assertExists(request.categoryId());

        if (repository.existsByCategoryIdAndNumber(request.categoryId(), request.number())) {
            throw new DuplicateRoundNumberException(request.number());
        }

        return mapper.toResponse(repository.save(mapper.toEntity(request)));
    }

    public List<RoundResponse> findByCategoryId(UUID categoryId) {
        return mapper.toResponseList(repository.findAllByCategoryIdOrderByNumberAsc(categoryId));
    }

    @Transactional
    public RoundResponse update(UUID id, UpdateRoundRequest request) {
        RoundEntity entity = findEntityById(id);
        categoryLookup.assertExists(request.categoryId());

        if (repository.existsByCategoryIdAndNumberAndIdNot(
                request.categoryId(), request.number(), id)) {
            throw new DuplicateRoundNumberException(request.number());
        }

        mapper.updateEntity(entity, request);

        return mapper.toResponse(repository.save(entity));
    }

    private RoundEntity findEntityById(UUID id) {
        return repository.findById(id)
                .orElseThrow(() -> new RoundNotFoundException(id));
    }

    @Override
    public void assertExists(UUID id) {
        findEntityById(id);
    }

    @Override
    public UUID findCategoryId(UUID roundId) {
        return findEntityById(roundId).getCategoryId();
    }

    @Override
    public List<UUID> findRoundIdsByCategoryId(UUID categoryId) {
        return repository.findAllByCategoryId(categoryId).stream()
                .map(RoundEntity::getId)
                .toList();
    }

}
