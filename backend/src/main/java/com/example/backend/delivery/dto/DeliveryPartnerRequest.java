package com.example.backend.delivery.dto;

import lombok.Data;
import java.util.UUID;

@Data
public class DeliveryPartnerRequest {
    private String name;
    private String phone;
    private String email;
    private String pinCode;
    private String vehicleNumber;
    private String vehicleType;
    private UUID outletId;
}
