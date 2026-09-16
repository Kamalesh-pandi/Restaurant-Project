package com.example.backend.customer.dto;

import jakarta.validation.constraints.NotBlank;
import java.time.LocalDate;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CustomerRequest {
    @NotBlank(message = "Phone number is required")
    private String phone;

    private String name;

    private String email;

    private LocalDate birthday;
}
