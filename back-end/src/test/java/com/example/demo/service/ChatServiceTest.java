package com.example.demo.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.header;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.jsonPath;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.method;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withStatus;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

import java.time.Duration;
import java.util.ArrayList;
import java.util.List;

import org.junit.jupiter.api.Test;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;

import com.example.demo.configuration.HuggingFaceProperties;
import com.example.demo.dto.ChatMessage;
import com.example.demo.dto.ChatRequest;
import com.example.demo.dto.ChatResponse;
import com.example.demo.exception.AiServiceException;

class ChatServiceTest {

    private static final String BASE = "https://router.example";
    private static final String MODEL = "meta-llama/Llama-3.1-8B-Instruct";

    private static HuggingFaceProperties props(String token) {
        return new HuggingFaceProperties(token, BASE, MODEL, "caption", "qa", 256, 0.5,
                Duration.ofSeconds(1), Duration.ofSeconds(1));
    }

    private MockRestServiceServer server;

    private ChatService service(String token) {
        RestClient.Builder builder = RestClient.builder().baseUrl(BASE)
                .defaultHeaders(h -> h.setBearerAuth("test-token"));
        server = MockRestServiceServer.bindTo(builder).build();
        return new ChatService(builder.build(), props(token));
    }

    @Test
    void sendsSystemPromptContextAndHistoryAndReturnsReply() {
        ChatService service = service("test-token");
        server.expect(requestTo(BASE + "/v1/chat/completions"))
                .andExpect(method(HttpMethod.POST))
                .andExpect(header("Authorization", "Bearer test-token"))
                .andExpect(jsonPath("$.model").value(MODEL))
                .andExpect(jsonPath("$.max_tokens").value(256))
                .andExpect(jsonPath("$.messages[0].role").value("system"))
                .andExpect(jsonPath("$.messages[0].content").value(org.hamcrest.Matchers.containsString("Drank 1.2 L")))
                .andExpect(jsonPath("$.messages[1].content").value("How much water should I drink?"))
                .andRespond(withSuccess("""
                        {"id":"x","model":"%s","object":"chat.completion",
                         "choices":[{"index":0,"finish_reason":"stop",
                           "message":{"role":"assistant","content":"  About 2 to 3 litres a day.  "}}],
                         "usage":{"total_tokens":10}}""".formatted(MODEL), MediaType.APPLICATION_JSON));

        ChatResponse response = service.chat(new ChatRequest(
                List.of(new ChatMessage("user", "How much water should I drink?")), "Drank 1.2 L today"));

        assertThat(response.reply()).isEqualTo("About 2 to 3 litres a day.");
        assertThat(response.model()).isEqualTo(MODEL);
        server.verify();
    }

    @Test
    void keepsOnlyTheMostRecentTurns() {
        ChatService service = service("test-token");
        List<ChatMessage> history = new ArrayList<>();
        for (int i = 0; i < 30; i++) {
            history.add(new ChatMessage(i % 2 == 0 ? "user" : "assistant", "m" + i));
        }
        history.add(new ChatMessage("user", "last"));

        List<ChatMessage> sent = service.buildMessages(new ChatRequest(history, null));

        assertThat(sent).hasSize(ChatService.MAX_HISTORY + 1);
        assertThat(sent.getFirst().role()).isEqualTo("system");
        assertThat(sent.getLast().content()).isEqualTo("last");
    }

    @Test
    void failsClearlyWhenTokenIsMissing() {
        ChatService service = service("");
        assertThatThrownBy(() -> service.chat(new ChatRequest(List.of(new ChatMessage("user", "hi")), null)))
                .isInstanceOf(AiServiceException.class)
                .hasMessageContaining("HF_TOKEN")
                .extracting(e -> ((AiServiceException) e).getStatus()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE);
    }

    @Test
    void rejectsConversationNotEndingWithUser() {
        ChatService service = service("test-token");
        assertThatThrownBy(() -> service.chat(new ChatRequest(List.of(new ChatMessage("assistant", "hi")), null)))
                .isInstanceOf(AiServiceException.class)
                .extracting(e -> ((AiServiceException) e).getStatus()).isEqualTo(HttpStatus.BAD_REQUEST);
    }

    @Test
    void mapsRateLimitToServiceUnavailable() {
        ChatService service = service("test-token");
        server.expect(requestTo(BASE + "/v1/chat/completions"))
                .andRespond(withStatus(HttpStatus.TOO_MANY_REQUESTS).body("{\"error\":\"rate limited\"}"));

        assertThatThrownBy(() -> service.chat(new ChatRequest(List.of(new ChatMessage("user", "hi")), null)))
                .isInstanceOf(AiServiceException.class)
                .extracting(e -> ((AiServiceException) e).getStatus()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE);
    }

    @Test
    void explainsMissingCredits() {
        ChatService service = service("test-token");
        server.expect(requestTo(BASE + "/v1/chat/completions"))
                .andRespond(withStatus(HttpStatus.PAYMENT_REQUIRED).body(
                        "{\"error\":\"Purchase pre-paid credits to continue using Inference Providers.\"}"));

        assertThatThrownBy(() -> service.chat(new ChatRequest(List.of(new ChatMessage("user", "hi")), null)))
                .isInstanceOf(AiServiceException.class)
                .hasMessageContaining("no Inference Providers credits")
                .extracting(e -> ((AiServiceException) e).getStatus()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE);
    }

    @Test
    void mapsAuthErrorToBadGatewayWithHint() {
        ChatService service = service("test-token");
        server.expect(requestTo(BASE + "/v1/chat/completions"))
                .andRespond(withStatus(HttpStatus.FORBIDDEN).body("{\"error\":\"gated\"}"));

        assertThatThrownBy(() -> service.chat(new ChatRequest(List.of(new ChatMessage("user", "hi")), null)))
                .isInstanceOf(AiServiceException.class)
                .hasMessageContaining("licence")
                .extracting(e -> ((AiServiceException) e).getStatus()).isEqualTo(HttpStatus.BAD_GATEWAY);
    }
}
