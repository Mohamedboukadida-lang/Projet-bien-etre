package com.example.demo.configuration;

import java.time.Duration;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "huggingface")
public record HuggingFaceProperties(
        String token,
        String baseUrl,
        String chatModel,
        String captionModel,
        String qaModel,
        int maxTokens,
        double temperature,
        Duration connectTimeout,
        Duration readTimeout) {

    public boolean hasToken() {
        return token != null && !token.isBlank();
    }
}
