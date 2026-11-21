package com.example.demo.dto;

import java.util.List;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;

/**
 * @param messages conversation so far, oldest first; the last one must come from the user
 * @param context  optional facts about the user (e.g. today's water intake) added to the system prompt
 */
public record ChatRequest(
        @NotEmpty @Size(max = 50) List<@Valid ChatMessage> messages,
        @Size(max = 2000) String context) {
}
