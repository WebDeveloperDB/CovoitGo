package com.covoitgo.api.exceptions;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

/**
 * Wird geworfen, wenn versucht wird, ein Konto mit einer bereits existierenden E-Mail zu registrieren.
 * Gibt automatisch den HTTP-Status 400 Bad Request zurück.
 */
@ResponseStatus(HttpStatus.BAD_REQUEST)
public class EmailDejaUtiliseException extends RuntimeException {
    public EmailDejaUtiliseException(String message) {
        super(message);
    }
}
