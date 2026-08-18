package br.com.flagplatform.modality.config;

import br.com.flagplatform.common.enums.ContactType;
import br.com.flagplatform.modality.entity.ModalityEntity;
import br.com.flagplatform.modality.repository.ModalityRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Seed padrão das modalidades (Flag 5x5, 8x8, 9x9 e Full Pads 11x11).
 * <p>
 * Aplicado em tempo de execução para funcionar independente da ordem
 * Flyway x ddl-auto do Hibernate (em teste, create-drop recria as tabelas
 * após o Flyway, apagando inserts de migration).
 */
@Slf4j
@RequiredArgsConstructor
@Component
public class ModalityDataSeeder implements CommandLineRunner {

    private final ModalityRepository repository;

    @Override
    @Transactional
    public void run(String... args) {
        if (repository.count() > 0) {
            return;
        }
        List<ModalityEntity> seeds = List.of(
                seed("Flag Football", "5x5", ContactType.FLAG, 5),
                seed("Flag Football", "8x8", ContactType.FLAG, 8),
                seed("Flag Football", "9x9", ContactType.FLAG, 9),
                seed("Full Pads", "11x11", ContactType.FULL_PAD, 11));
        repository.saveAll(seeds);
        log.info("Modalidades padrão aplicadas ({} itens)", seeds.size());
    }

    private ModalityEntity seed(String name, String format, ContactType contactType, int playersPerTeam) {
        ModalityEntity entity = new ModalityEntity();
        entity.setName(name);
        entity.setFormat(format);
        entity.setContactType(contactType);
        entity.setPlayersPerTeam(playersPerTeam);
        entity.setActive(true);
        return entity;
    }

}
