package com.example.demo.controller;

import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import com.example.demo.service.ImageCaptioningService;

@RestController
@RequestMapping("/api")
public class ImageCaptioningController {

    private final ImageCaptioningService imageCaptioningService;

    public ImageCaptioningController(ImageCaptioningService imageCaptioningService) {
        this.imageCaptioningService = imageCaptioningService;
    }

    @PostMapping("/image-caption")
    public ResponseEntity<String> generateImageCaption(@RequestParam("file") MultipartFile file) {
        return ResponseEntity.ok()
                .contentType(MediaType.APPLICATION_JSON)
                .body(imageCaptioningService.generateCaption(file));
    }
}
