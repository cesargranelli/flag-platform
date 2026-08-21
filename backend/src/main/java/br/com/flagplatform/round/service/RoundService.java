package br.com.flagplatform.round.service;

import br.com.flagplatform.competition.CompetitionLookup;
import br.com.flagplatform.round.RoundInfo;
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
    private final CompetitionLookup competitionLookup;

    @Transactional
    public RoundResponse create(CreateRoundRequest request) {
        competitionLookup.assertExists(request.competitionId());

        if (repository.existsByCompetitionIdAndNumber(request.competitionId(), request.number())) {
            throw new DuplicateRoundNumberException(request.number());
        }

        return mapper.toResponse(repository.save(mapper.toEntity(request)));
    }

    public List<RoundResponse> findByCompetitionId(UUID competitionId) {
        return mapper.toResponseList(repository.findAllByCompetitionIdOrderByNumberAsc(competitionId));
    }

    public RoundResponse findById(UUID id) {
        return mapper.toResponse(findEntityById(id));
    }

    @Transactional
    public RoundResponse update(UUID id, UpdateRoundRequest request) {
        RoundEntity entity = findEntityById(id);
        competitionLookup.assertExists(request.competitionId());

        if (repository.existsByCompetitionIdAndNumberAndIdNot(
                request.competitionId(), request.number(), id)) {
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
    public UUID findCompetitionId(UUID roundId) {
        return findEntityById(roundId).getCompetitionId();
    }

    @Override
    public List<UUID> findRoundIdsByCompetitionId(UUID competitionId) {
        return repository.findAllByCompetitionId(competitionId).stream()
                .map(RoundEntity::getId)
                .toList();
    }

    @Override
    public List<RoundInfo> findRoundInfoByCompetitionId(UUID competitionId) {
        return repository.findAllByCompetitionId(competitionId).stream()
                .map(round -> new RoundInfo(round.getId(), round.getNumber()))
                .toList();
    }

    @Override
    public RoundInfo findRoundInfoById(UUID roundId) {
        RoundEntity round = findEntityById(roundId);
        return new RoundInfo(round.getId(), round.getNumber());
    }

}
