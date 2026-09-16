package com.example.backend.delivery.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DeliveryPartnerStatsResponse {
    private UUID partnerId;
    private String name;
    private String phone;
    private Double rating;
    private String status;
    private Integer totalDeliveries;
    private Integer todayDeliveriesCount;
    private BigDecimal todayEarnings;
    private BigDecimal todayTips;
    private Integer weeklyDeliveriesCount;
    private BigDecimal weeklyEarnings;
    private BigDecimal allTimeEarnings;
    private Double completionRate;
    private Integer avgDeliveryMinutes;
    private Double totalDistanceKm;
}
