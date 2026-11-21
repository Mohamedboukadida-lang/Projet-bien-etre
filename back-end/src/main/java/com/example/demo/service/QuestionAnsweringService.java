package com.example.demo.service;

import java.util.Map;

import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import com.example.demo.configuration.HuggingFaceProperties;

@Service
public class QuestionAnsweringService {

    private final RestClient restClient;
    private final HuggingFaceProperties props;

    public QuestionAnsweringService(@Qualifier("huggingFaceRestClient") RestClient restClient, HuggingFaceProperties props) {
        this.restClient = restClient;
        this.props = props;
    }

    /** Returns the provider's JSON answer, e.g. {@code {"answer":"...","score":0.9,...}}. */
    public String query(String question, String context) {
        HuggingFaceCalls.requireToken(props);
        Map<String, Object> body = Map.of("inputs", Map.of("question", question, "context", context));
        return HuggingFaceCalls.call(props.qaModel(), () -> restClient.post()
                .uri("/hf-inference/models/{model}", props.qaModel())
                .contentType(MediaType.APPLICATION_JSON)
                .body(body)
                .retrieve()
                .body(String.class));
    }
}
