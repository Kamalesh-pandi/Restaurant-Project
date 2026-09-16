package com.example.backend.delivery.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DeliveryPinLoginResponse {
    private String token;
    private DeliveryPartnerResponse partner;
}
