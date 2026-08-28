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

import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@RequiredArgsConstructor
@Transactional(readOnly = true)
@Service
public class RoundService implements RoundLookup {

    private final RoundMapper mapper;
    private final RoundRepository repository;
    private final CompetitionLookup competitionLookup;

    @Transactional
    public RoundResponse create(CreateRoundRequest request, String currentUserEmail) {
        // V260: apenas o criador do campeonato (ou ADMIN) gerencia o campeonato.
        competitionLookup.assertManagedBy(request.competitionId(), currentUserEmail);
        // Issue #305: estrutura só é editável com o campeonato em DRAFT.
        competitionLookup.assertEditable(request.competitionId());

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
    public RoundResponse update(UUID id, UpdateRoundRequest request, String currentUserEmail) {
        RoundEntity entity = findEntityById(id);

        // V260: valida o campeonato atual da rodada e, se houver mudança,
        // também o campeonato de destino.
        competitionLookup.assertManagedBy(entity.getCompetitionId(), currentUserEmail);
        if (!entity.getCompetitionId().equals(request.competitionId())) {
            competitionLookup.assertManagedBy(request.competitionId(), currentUserEmail);
        }
        // Issue #305: estrutura só é editável com o campeonato em DRAFT
        // (valida a rodada e o destino, se diferente).
        competitionLookup.assertEditable(entity.getCompetitionId());
        if (!entity.getCompetitionId().equals(request.competitionId())) {
            competitionLookup.assertEditable(request.competitionId());
        }

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

    @Override
    public Map<UUID, UUID> findCompetitionIdsByRoundIds(Collection<UUID> roundIds) {
        if (roundIds == null || roundIds.isEmpty()) {
            return Map.of();
        }
        return repository.findAllById(roundIds).stream()
                .collect(Collectors.toMap(RoundEntity::getId, RoundEntity::getCompetitionId));
    }

    @Override
    public Map<UUID, RoundInfo> findRoundInfoByIds(Collection<UUID> roundIds) {
        if (roundIds == null || roundIds.isEmpty()) {
            return Map.of();
        }
        return repository.findAllById(roundIds).stream()
                .map(round -> new RoundInfo(round.getId(), round.getNumber()))
                .collect(Collectors.toMap(RoundInfo::id, info -> info));
    }

}
