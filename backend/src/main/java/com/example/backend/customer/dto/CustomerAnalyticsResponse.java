package com.example.backend.customer.dto;

import java.math.BigDecimal;
import java.util.UUID;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CustomerAnalyticsResponse {
    private UUID customerId;
    private String name;
    private int totalVisits;
    private BigDecimal totalSpend;
    private BigDecimal averageOrderValue;
    private double loyaltyRedemptionRate;
}
