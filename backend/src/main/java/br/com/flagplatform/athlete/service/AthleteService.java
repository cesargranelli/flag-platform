package br.com.flagplatform.athlete.service;

import br.com.flagplatform.athlete.AthleteInfo;
import br.com.flagplatform.athlete.AthleteLookup;
import br.com.flagplatform.athlete.dto.request.CreateAthleteRequest;
import br.com.flagplatform.athlete.dto.request.UpdateAthleteRequest;
import br.com.flagplatform.athlete.dto.response.AthleteResponse;
import br.com.flagplatform.athlete.entity.AthleteEntity;
import br.com.flagplatform.athlete.exception.AthleteNotFoundException;
import br.com.flagplatform.athlete.mapper.AthleteMapper;
import br.com.flagplatform.athlete.repository.AthleteRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@RequiredArgsConstructor
@Transactional(readOnly = true)
@Service
public class AthleteService implements AthleteLookup {

    private final AthleteMapper mapper;
    private final AthleteRepository repository;

    @Transactional
    public AthleteResponse create(CreateAthleteRequest request) {
        return mapper.toResponse(repository.save(mapper.toEntity(request)));
    }

    public List<AthleteResponse> findAll() {
        return mapper.toResponseList(repository.findAllByOrderByNameAsc());
    }

    public AthleteResponse findById(UUID id) {
        return mapper.toResponse(findEntityById(id));
    }

    @Transactional
    public AthleteResponse update(UUID id, UpdateAthleteRequest request) {
        AthleteEntity entity = findEntityById(id);
        mapper.updateEntity(entity, request);

        return mapper.toResponse(repository.save(entity));
    }

    private AthleteEntity findEntityById(UUID id) {
        return repository.findById(id)
                .orElseThrow(() -> new AthleteNotFoundException(id));
    }

    @Override
    public void assertExists(UUID id) {
        findEntityById(id);
    }

    @Override
    public AthleteInfo findAthleteInfoById(UUID id) {
        AthleteEntity entity = findEntityById(id);
        return new AthleteInfo(
                entity.getId(),
                entity.getName(),
                entity.getNickname(),
                entity.getPosition(),
                entity.getNumber(),
                entity.getPhotoUrl());
    }

}
