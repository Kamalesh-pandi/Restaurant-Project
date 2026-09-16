package com.example.backend.delivery.dto;

import lombok.Data;

@Data
public class CompleteDeliveryRequest {
    private String otpCode;
    private String notes;
}
