package br.com.flagplatform.standing.service;

import br.com.flagplatform.game.GameResultRegisteredEvent;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.UUID;

import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
class StandingEventListenerTest {

    @Mock
    private StandingService standingService;

    @InjectMocks
    private StandingEventListener listener;

    @Test
    void onGameResultRegistered_recalculatesStandingsForCategory() {
        UUID gameId = UUID.randomUUID();
        UUID categoryId = UUID.randomUUID();

        listener.onGameResultRegistered(new GameResultRegisteredEvent(gameId, categoryId));

        verify(standingService).recalculate(categoryId);
    }
}
