package br.com.flagplatform.team.service;

import br.com.flagplatform.category.CategoryLookup;
import br.com.flagplatform.team.TeamInfo;
import br.com.flagplatform.team.TeamLookup;
import br.com.flagplatform.team.dto.request.CreateTeamRequest;
import br.com.flagplatform.team.dto.request.UpdateTeamRequest;
import br.com.flagplatform.team.dto.response.TeamResponse;
import br.com.flagplatform.team.entity.TeamEntity;
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
    private final CategoryLookup categoryLookup;

    @Transactional
    public TeamResponse create(CreateTeamRequest request) {
        categoryLookup.assertExists(request.categoryId());

        if (repository.existsByCategoryIdAndNameIgnoreCase(request.categoryId(), request.name())) {
            throw new DuplicateTeamNameException(request.name());
        }

        return mapper.toResponse(repository.save(mapper.toEntity(request)));
    }

    public List<TeamResponse> findByCategoryId(UUID categoryId) {
        return mapper.toResponseList(repository.findAllByCategoryIdOrderByNameAsc(categoryId));
    }

    public TeamResponse findById(UUID id) {
        return mapper.toResponse(findEntityById(id));
    }

    @Transactional
    public TeamResponse update(UUID id, UpdateTeamRequest request) {
        TeamEntity entity = findEntityById(id);
        categoryLookup.assertExists(request.categoryId());

        if (repository.existsByCategoryIdAndNameIgnoreCaseAndIdNot(
                request.categoryId(), request.name(), id)) {
            throw new DuplicateTeamNameException(request.name());
        }

        mapper.updateEntity(entity, request);

        return mapper.toResponse(repository.save(entity));
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
    public List<UUID> findTeamIdsByCategoryId(UUID categoryId) {
        return repository.findAllByCategoryIdOrderByNameAsc(categoryId).stream()
                .map(TeamEntity::getId)
                .toList();
    }

    @Override
    public List<TeamInfo> findTeamInfoByCategoryId(UUID categoryId) {
        return repository.findAllByCategoryIdOrderByNameAsc(categoryId).stream()
                .map(team -> new TeamInfo(team.getId(), team.getName()))
                .toList();
    }

}
