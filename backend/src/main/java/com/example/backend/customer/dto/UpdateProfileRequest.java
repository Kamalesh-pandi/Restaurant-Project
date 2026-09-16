package com.example.backend.customer.dto;

import java.time.LocalDate;
import java.util.UUID;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdateProfileRequest {
    private UUID customerId;
    private String id;
    private String name;
    private String phone;
    private String email;
    private String address;
    private LocalDate birthday;
}
