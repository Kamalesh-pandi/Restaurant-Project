package com.example.backend.delivery.dto;

import com.example.backend.delivery.entity.DeliveryPartnerStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DeliveryPartnerResponse {
    private UUID partnerId;
    private String name;
    private String phone;
    private String email;
    private String vehicleNumber;
    private String vehicleType;
    private DeliveryPartnerStatus status;
    private Double currentLat;
    private Double currentLng;
    private LocalDateTime lastLocationUpdate;
    private UUID outletId;
    private Double rating;
    private Integer totalDeliveries;
    private Boolean isApproved;
    private Boolean isActive;
}
