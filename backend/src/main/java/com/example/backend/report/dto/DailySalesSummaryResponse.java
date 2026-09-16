package com.example.backend.report.dto;

import java.math.BigDecimal;
import java.util.Map;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DailySalesSummaryResponse {
    private BigDecimal gmv;
    private int totalCovers;
    private BigDecimal aov;
    private Map<String, BigDecimal> paymentMethodMix;
    private Map<Integer, BigDecimal> hourlyRevenueTrend;
}
