package com.example.demo.service;

import java.util.function.Supplier;

import org.springframework.http.HttpStatus;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClientResponseException;

import com.example.demo.configuration.HuggingFaceProperties;
import com.example.demo.exception.AiServiceException;

/** Translates Hugging Face failures into errors the app can show to the user. */
final class HuggingFaceCalls {

    private HuggingFaceCalls() {
    }

    static void requireToken(HuggingFaceProperties props) {
        if (!props.hasToken()) {
            throw new AiServiceException(HttpStatus.SERVICE_UNAVAILABLE,
                    "The AI service is not configured: set the HF_TOKEN environment variable and restart it.");
        }
    }

    static <T> T call(String model, Supplier<T> request) {
        try {
            return request.get();
        } catch (RestClientResponseException e) {
            int code = e.getStatusCode().value();
            String upstream = e.getResponseBodyAsString();
            if (code == 401 || code == 403) {
                throw new AiServiceException(HttpStatus.BAD_GATEWAY,
                        "Hugging Face refused the request for model " + model
                                + " (check HF_TOKEN permissions and, for gated models, accept the licence): " + upstream, e);
            }
            if (code == 404 || code == 400 && upstream.contains("model")) {
                throw new AiServiceException(HttpStatus.BAD_GATEWAY,
                        "Model " + model + " is not available on Hugging Face Inference Providers: " + upstream, e);
            }
            if (code == 429 || code == 503) {
                throw new AiServiceException(HttpStatus.SERVICE_UNAVAILABLE,
                        "The AI model is busy or rate limited, please try again in a moment.", e);
            }
            throw new AiServiceException(HttpStatus.BAD_GATEWAY,
                    "Hugging Face returned HTTP " + code + ": " + upstream, e);
        } catch (ResourceAccessException e) {
            throw new AiServiceException(HttpStatus.GATEWAY_TIMEOUT,
                    "Could not reach Hugging Face in time, please try again.", e);
        }
    }
}
