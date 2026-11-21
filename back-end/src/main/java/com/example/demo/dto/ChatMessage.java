package com.example.demo.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/** One turn of the conversation as sent by the app. Only "user" and "assistant" roles are accepted from clients. */
public record ChatMessage(
        @NotBlank @Pattern(regexp = "user|assistant") String role,
        @NotBlank @Size(max = 4000) String content) {
}
