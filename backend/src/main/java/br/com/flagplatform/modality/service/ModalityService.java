package br.com.flagplatform.modality.service;

import br.com.flagplatform.modality.ModalityInfo;
import br.com.flagplatform.modality.ModalityLookup;
import br.com.flagplatform.modality.dto.response.ModalityResponse;
import br.com.flagplatform.modality.entity.ModalityEntity;
import br.com.flagplatform.modality.exception.ModalityNotFoundException;
import br.com.flagplatform.modality.mapper.ModalityMapper;
import br.com.flagplatform.modality.repository.ModalityRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@RequiredArgsConstructor
@Transactional(readOnly = true)
@Service
public class ModalityService implements ModalityLookup {

    private final ModalityMapper mapper;
    private final ModalityRepository repository;

    public List<ModalityResponse> listActive() {
        return mapper.toResponseList(repository.findAllByActiveTrueOrderByFormatAsc());
    }

    public ModalityResponse findById(UUID id) {
        return mapper.toResponse(findEntityById(id));
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
    public ModalityInfo findModalityInfoById(UUID id) {
        ModalityEntity entity = findEntityById(id);
        return new ModalityInfo(entity.getId(), entity.getName(), entity.getFormat());
    }

    @Override
    public List<ModalityInfo> listModalityInfo() {
        return repository.findAllByActiveTrueOrderByFormatAsc().stream()
                .map(entity -> new ModalityInfo(entity.getId(), entity.getName(), entity.getFormat()))
                .toList();
    }

    private ModalityEntity findEntityById(UUID id) {
        return repository.findById(id)
                .orElseThrow(() -> new ModalityNotFoundException(id));
    }

}
