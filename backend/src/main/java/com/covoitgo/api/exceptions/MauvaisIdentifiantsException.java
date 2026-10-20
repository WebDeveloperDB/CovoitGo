package com.covoitgo.api.exceptions;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

/**
 * Wird geworfen, wenn die E-Mail oder das Passwort nicht stimmen.
 * Gibt automatisch den HTTP-Status 401 Unauthorized zurück.
 */
@ResponseStatus(HttpStatus.UNAUTHORIZED)
public class MauvaisIdentifiantsException extends RuntimeException {
    public MauvaisIdentifiantsException(String message) {
        super(message);
    }
}
