package com.example.backend.report.dto;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CustomerAnalyticsReportResponse {
    private long newVisits;
    private long returningVisits;
    private double loyaltyRedemptionRate;
    private double averageFeedbackScore;
}
