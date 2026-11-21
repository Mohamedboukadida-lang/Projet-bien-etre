package com.example.demo.configuration;

import java.net.http.HttpClient;

import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.BufferingClientHttpRequestFactory;
import org.springframework.http.client.JdkClientHttpRequestFactory;
import org.springframework.web.client.RestClient;

@Configuration
@EnableConfigurationProperties(HuggingFaceProperties.class)
public class HuggingFaceClientConfig {

    @Bean
    public RestClient huggingFaceRestClient(RestClient.Builder builder, HuggingFaceProperties props) {
        HttpClient httpClient = HttpClient.newBuilder()
                .connectTimeout(props.connectTimeout())
                .build();
        JdkClientHttpRequestFactory requestFactory = new JdkClientHttpRequestFactory(httpClient);
        requestFactory.setReadTimeout(props.readTimeout());

        RestClient.Builder configured = builder
                .baseUrl(props.baseUrl())
                // Buffer bodies so a Content-Length is sent instead of chunked encoding.
                .requestFactory(new BufferingClientHttpRequestFactory(requestFactory));
        if (props.hasToken()) {
            configured = configured.defaultHeaders(h -> h.setBearerAuth(props.token()));
        }
        return configured.build();
    }
}
