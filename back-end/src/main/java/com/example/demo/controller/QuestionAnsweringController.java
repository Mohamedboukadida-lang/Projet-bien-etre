package com.example.demo.controller;

import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.demo.dto.QueryInput;
import com.example.demo.service.QuestionAnsweringService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api")
public class QuestionAnsweringController {

    private final QuestionAnsweringService qaService;

    public QuestionAnsweringController(QuestionAnsweringService qaService) {
        this.qaService = qaService;
    }

    @PostMapping("/ask")
    public ResponseEntity<String> askQuestion(@Valid @RequestBody QueryInput input) {
        return ResponseEntity.ok()
                .contentType(MediaType.APPLICATION_JSON)
                .body(qaService.query(input.question(), input.context()));
    }
}
