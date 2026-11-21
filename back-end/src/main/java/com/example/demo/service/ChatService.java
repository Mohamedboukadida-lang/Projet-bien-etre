package com.example.demo.service;

import java.util.ArrayList;
import java.util.List;

import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import com.example.demo.configuration.HuggingFaceProperties;
import com.example.demo.dto.ChatMessage;
import com.example.demo.dto.ChatRequest;
import com.example.demo.dto.ChatResponse;
import com.example.demo.exception.AiServiceException;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * Well-being chatbot backed by an OpenAI-compatible chat model served through
 * Hugging Face Inference Providers (https://router.huggingface.co/v1/chat/completions).
 */
@Service
public class ChatService {

    /** Only the most recent turns are sent, to bound latency and cost. */
    static final int MAX_HISTORY = 20;

    static final String SYSTEM_PROMPT = """
            You are "Well-Being Coach", the assistant inside a personal well-being mobile app \
            that tracks hydration, sleep, workouts and meditation.
            - Give practical, encouraging, evidence-based advice about hydration, sleep, \
            exercise, nutrition, stress and healthy habits.
            - Keep answers short (at most 120 words) and easy to read on a phone; use short \
            bullet points when listing steps.
            - Answer in the same language the user writes in.
            - You are not a doctor: do not diagnose or prescribe. For worrying symptoms, \
            suggest seeing a health professional; for emergencies, tell the user to contact \
            local emergency services immediately.
            - If a question is unrelated to well-being, answer briefly and steer back to \
            how you can help with their well-being.""";

    private final RestClient restClient;
    private final HuggingFaceProperties props;

    public ChatService(@Qualifier("huggingFaceRestClient") RestClient restClient, HuggingFaceProperties props) {
        this.restClient = restClient;
        this.props = props;
    }

    public ChatResponse chat(ChatRequest request) {
        List<ChatMessage> history = request.messages();
        if (!"user".equals(history.getLast().role())) {
            throw new AiServiceException(HttpStatus.BAD_REQUEST, "The last message must come from the user.");
        }
        HuggingFaceCalls.requireToken(props);

        CompletionRequest body = new CompletionRequest(
                props.chatModel(), buildMessages(request), props.maxTokens(), props.temperature());

        CompletionResponse response = HuggingFaceCalls.call(props.chatModel(), () -> restClient.post()
                .uri("/v1/chat/completions")
                .contentType(MediaType.APPLICATION_JSON)
                .body(body)
                .retrieve()
                .body(CompletionResponse.class));

        String reply = extractReply(response);
        if (reply == null || reply.isBlank()) {
            throw new AiServiceException(HttpStatus.BAD_GATEWAY, "The AI model returned an empty answer.");
        }
        return new ChatResponse(reply.strip(), response.model() != null ? response.model() : props.chatModel());
    }

    List<ChatMessage> buildMessages(ChatRequest request) {
        String system = SYSTEM_PROMPT;
        if (request.context() != null && !request.context().isBlank()) {
            system += "\n\nWhat the app knows about the user right now (use it when relevant):\n"
                    + request.context().strip();
        }
        List<ChatMessage> history = request.messages();
        List<ChatMessage> messages = new ArrayList<>();
        messages.add(new ChatMessage("system", system));
        messages.addAll(history.subList(Math.max(0, history.size() - MAX_HISTORY), history.size()));
        return messages;
    }

    private static String extractReply(CompletionResponse response) {
        if (response == null || response.choices() == null || response.choices().isEmpty()) {
            return null;
        }
        Choice first = response.choices().getFirst();
        return first.message() == null ? null : first.message().content();
    }

    record CompletionRequest(
            String model,
            List<ChatMessage> messages,
            @JsonProperty("max_tokens") int maxTokens,
            double temperature) {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    record CompletionResponse(String model, List<Choice> choices) {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    record Choice(AssistantMessage message) {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    record AssistantMessage(String role, String content) {
    }
}
