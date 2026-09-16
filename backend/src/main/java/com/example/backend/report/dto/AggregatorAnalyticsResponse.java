package com.example.backend.report.dto;

import java.math.BigDecimal;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AggregatorAnalyticsResponse {
    private long swiggyOrders;
    private BigDecimal swiggyGmv;
    private BigDecimal swiggyCommission;

    private long zomatoOrders;
    private BigDecimal zomatoGmv;
    private BigDecimal zomatoCommission;

    private long directOrders;
    private BigDecimal directGmv;
}
