package br.com.flagplatform.standing.service;

import br.com.flagplatform.game.GameResultRegisteredEvent;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

@Component
@RequiredArgsConstructor
public class StandingEventListener {

    private final StandingService standingService;

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onGameResultRegistered(GameResultRegisteredEvent event) {
        standingService.recalculate(event.competitionId());
    }
}
