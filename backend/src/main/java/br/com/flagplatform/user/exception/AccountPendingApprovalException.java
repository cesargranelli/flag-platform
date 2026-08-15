package br.com.flagplatform.user.exception;

import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

public class AccountPendingApprovalException extends ApiException {

    public AccountPendingApprovalException(String message) {
        super(
                HttpStatus.FORBIDDEN,
                "Account not active",
                message,
                "account_pending_approval"
        );
    }

}
