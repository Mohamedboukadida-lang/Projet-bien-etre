package com.example.demo.exception;

import org.springframework.http.HttpStatus;

/** Raised when the AI provider cannot produce an answer; carries the HTTP status to return to the app. */
public class AiServiceException extends RuntimeException {

    private final HttpStatus status;

    public AiServiceException(HttpStatus status, String message) {
        super(message);
        this.status = status;
    }

    public AiServiceException(HttpStatus status, String message, Throwable cause) {
        super(message, cause);
        this.status = status;
    }

    public HttpStatus getStatus() {
        return status;
    }
}
