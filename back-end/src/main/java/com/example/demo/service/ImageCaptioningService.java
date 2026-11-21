package com.example.demo.service;

import java.io.IOException;

import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.multipart.MultipartFile;

import com.example.demo.configuration.HuggingFaceProperties;
import com.example.demo.exception.AiServiceException;

@Service
public class ImageCaptioningService {

    private final RestClient restClient;
    private final HuggingFaceProperties props;

    public ImageCaptioningService(@Qualifier("huggingFaceRestClient") RestClient restClient, HuggingFaceProperties props) {
        this.restClient = restClient;
        this.props = props;
    }

    /** Returns the provider's JSON answer, e.g. {@code [{"generated_text":"a glass of water"}]}. */
    public String generateCaption(MultipartFile file) {
        if (file.isEmpty()) {
            throw new AiServiceException(HttpStatus.BAD_REQUEST, "The uploaded image is empty.");
        }
        HuggingFaceCalls.requireToken(props);
        byte[] bytes;
        try {
            bytes = file.getBytes();
        } catch (IOException e) {
            throw new AiServiceException(HttpStatus.BAD_REQUEST, "Could not read the uploaded image.", e);
        }
        MediaType contentType = file.getContentType() != null
                ? MediaType.parseMediaType(file.getContentType())
                : MediaType.APPLICATION_OCTET_STREAM;

        return HuggingFaceCalls.call(props.captionModel(), () -> restClient.post()
                .uri("/hf-inference/models/{model}", props.captionModel())
                .contentType(contentType)
                .body(bytes)
                .retrieve()
                .body(String.class));
    }
}
