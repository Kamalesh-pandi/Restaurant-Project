package com.example.backend.staff.dto;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PinLoginRequest {
    private String name;
    private String pin;
}
