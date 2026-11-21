package com.example.demo.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record QueryInput(
        @NotBlank @Size(max = 1000) String question,
        @NotBlank @Size(max = 10000) String context) {
}
