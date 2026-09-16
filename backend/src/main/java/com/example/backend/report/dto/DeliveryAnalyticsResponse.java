package com.example.backend.report.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DeliveryAnalyticsResponse {

    private long totalDeliveryOrders;
    private long totalTakeawayOrders;
    private BigDecimal totalDeliveryRevenue;
    private BigDecimal totalTakeawayRevenue;
    private double averageDeliveryTimeMinutes;
    private long activeDeliveryPartnersCount;
}
