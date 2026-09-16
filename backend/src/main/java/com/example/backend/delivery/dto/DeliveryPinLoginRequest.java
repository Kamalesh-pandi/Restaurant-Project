package com.example.backend.delivery.dto;

import lombok.Data;

@Data
public class DeliveryPinLoginRequest {
    private String phone;
    private String pinCode;
}
