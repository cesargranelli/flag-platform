package br.com.flagplatform.roster.service;

import br.com.flagplatform.athlete.AthleteInfo;
import br.com.flagplatform.athlete.AthleteLookup;
import br.com.flagplatform.common.enums.AthletePosition;
import br.com.flagplatform.common.enums.RosterStatus;
import br.com.flagplatform.roster.dto.request.AddRosterEntryRequest;
import br.com.flagplatform.roster.dto.response.RosterEntryResponse;
import br.com.flagplatform.roster.entity.RosterEntryEntity;
import br.com.flagplatform.roster.exception.DuplicateRosterEntryException;
import br.com.flagplatform.roster.exception.RosterEntryNotFoundException;
import br.com.flagplatform.roster.mapper.RosterEntryMapper;
import br.com.flagplatform.roster.repository.RosterEntryRepository;
import br.com.flagplatform.team.TeamLookup;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class RosterServiceTest {

    @Mock
    private RosterEntryMapper mapper;

    @Mock
    private RosterEntryRepository repository;

    @Mock
    private TeamLookup teamLookup;

    @Mock
    private AthleteLookup athleteLookup;

    @InjectMocks
    private RosterService service;

    @Test
    void add_savesEntryWithDefaultActiveStatus() {
        UUID teamId = UUID.randomUUID();
        UUID athleteId = UUID.randomUUID();
        AddRosterEntryRequest request = new AddRosterEntryRequest(athleteId, null);
        RosterEntryEntity entity = entity(teamId, athleteId, null);
        AthleteInfo info = info(athleteId, "João Silva", "João", AthletePosition.QB, 7, null);

        when(mapper.toEntity(request)).thenReturn(entity);
        when(repository.existsByTeamIdAndAthleteId(teamId, athleteId)).thenReturn(false);
        when(repository.save(entity)).thenReturn(entity);
        when(athleteLookup.findAthleteInfoById(athleteId)).thenReturn(info);

        RosterEntryResponse response = service.add(teamId, request);

        assertThat(response.athleteName()).isEqualTo("João Silva");
        assertThat(response.athleteId()).isEqualTo(athleteId);
        assertThat(response.status()).isEqualTo(RosterStatus.ACTIVE);
        assertThat(entity.getTeamId()).isEqualTo(teamId);
        verify(teamLookup).assertExists(teamId);
        verify(athleteLookup).assertExists(athleteId);
        verify(repository).save(entity);
    }

    @Test
    void add_usesProvidedStatus() {
        UUID teamId = UUID.randomUUID();
        UUID athleteId = UUID.randomUUID();
        AddRosterEntryRequest request = new AddRosterEntryRequest(athleteId, RosterStatus.INACTIVE);
        RosterEntryEntity entity = entity(teamId, athleteId, RosterStatus.INACTIVE);

        when(mapper.toEntity(request)).thenReturn(entity);
        when(repository.existsByTeamIdAndAthleteId(teamId, athleteId)).thenReturn(false);
        when(repository.save(entity)).thenReturn(entity);
        when(athleteLookup.findAthleteInfoById(athleteId))
                .thenReturn(info(athleteId, "João Silva", null, null, null, null));

        RosterEntryResponse response = service.add(teamId, request);

        assertThat(response.status()).isEqualTo(RosterStatus.INACTIVE);
    }

    @Test
    void add_throwsWhenTeamNotFound() {
        UUID teamId = UUID.randomUUID();
        UUID athleteId = UUID.randomUUID();
        AddRosterEntryRequest request = new AddRosterEntryRequest(athleteId, null);

        doThrow(new RuntimeException("team not found"))
                .when(teamLookup).assertExists(teamId);

        assertThatThrownBy(() -> service.add(teamId, request))
                .isInstanceOf(RuntimeException.class);

        verify(repository, never()).save(entity(teamId, athleteId, null));
    }

    @Test
    void add_throwsWhenAthleteNotFound() {
        UUID teamId = UUID.randomUUID();
        UUID athleteId = UUID.randomUUID();
        AddRosterEntryRequest request = new AddRosterEntryRequest(athleteId, null);

        doThrow(new RuntimeException("athlete not found"))
                .when(athleteLookup).assertExists(athleteId);

        assertThatThrownBy(() -> service.add(teamId, request))
                .isInstanceOf(RuntimeException.class);

        verify(repository, never()).save(entity(teamId, athleteId, null));
    }

    @Test
    void add_throwsWhenAthleteAlreadyRegistered() {
        UUID teamId = UUID.randomUUID();
        UUID athleteId = UUID.randomUUID();
        AddRosterEntryRequest request = new AddRosterEntryRequest(athleteId, null);

        when(repository.existsByTeamIdAndAthleteId(teamId, athleteId)).thenReturn(true);

        assertThatThrownBy(() -> service.add(teamId, request))
                .isInstanceOf(DuplicateRosterEntryException.class);

        verify(repository, never()).save(entity(teamId, athleteId, null));
    }

    @Test
    void findRosterByTeam_returnsEntriesOrderedByName() {
        UUID teamId = UUID.randomUUID();
        UUID biaId = UUID.randomUUID();
        UUID anaId = UUID.randomUUID();

        RosterEntryEntity biaEntry = entity(teamId, biaId, RosterStatus.ACTIVE);
        RosterEntryEntity anaEntry = entity(teamId, anaId, RosterStatus.ACTIVE);

        when(repository.findAllByTeamIdOrderByCreatedAtAsc(teamId))
                .thenReturn(List.of(biaEntry, anaEntry));
        when(athleteLookup.findAthleteInfoById(biaId))
                .thenReturn(info(biaId, "Bia Santos", "Bia", AthletePosition.DB, 21, null));
        when(athleteLookup.findAthleteInfoById(anaId))
                .thenReturn(info(anaId, "Ana Souza", "Ana", AthletePosition.RB, 3, null));

        List<RosterEntryResponse> response = service.findRosterByTeam(teamId);

        assertThat(response).hasSize(2);
        assertThat(response.get(0).athleteName()).isEqualTo("Ana Souza");
        assertThat(response.get(1).athleteName()).isEqualTo("Bia Santos");
        verify(teamLookup).assertExists(teamId);
    }

    @Test
    void findRosterByTeam_throwsWhenTeamNotFound() {
        UUID teamId = UUID.randomUUID();

        doThrow(new RuntimeException("team not found"))
                .when(teamLookup).assertExists(teamId);

        assertThatThrownBy(() -> service.findRosterByTeam(teamId))
                .isInstanceOf(RuntimeException.class);

        verify(repository, never()).findAllByTeamIdOrderByCreatedAtAsc(teamId);
    }

    @Test
    void remove_deletesExistingEntry() {
        UUID teamId = UUID.randomUUID();
        UUID athleteId = UUID.randomUUID();
        RosterEntryEntity entity = entity(teamId, athleteId, RosterStatus.ACTIVE);

        when(repository.findByTeamIdAndAthleteId(teamId, athleteId))
                .thenReturn(Optional.of(entity));

        service.remove(teamId, athleteId);

        verify(repository).delete(entity);
    }

    @Test
    void remove_throwsWhenEntryNotFound() {
        UUID teamId = UUID.randomUUID();
        UUID athleteId = UUID.randomUUID();

        when(repository.findByTeamIdAndAthleteId(teamId, athleteId))
                .thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.remove(teamId, athleteId))
                .isInstanceOf(RosterEntryNotFoundException.class);

        verify(repository, never()).delete(entity(teamId, athleteId, null));
    }

    private RosterEntryEntity entity(UUID teamId, UUID athleteId, RosterStatus status) {
        RosterEntryEntity entity = new RosterEntryEntity();
        entity.setId(UUID.randomUUID());
        entity.setTeamId(teamId);
        entity.setAthleteId(athleteId);
        entity.setStatus(status);
        return entity;
    }

    private AthleteInfo info(UUID id, String name, String nickname,
                             AthletePosition position, Integer number, String photoUrl) {
        return new AthleteInfo(id, name, nickname, position, number, photoUrl);
    }

}
