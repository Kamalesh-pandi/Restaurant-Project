package com.example.backend.report.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Map;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class XReportResponse {
    private LocalDateTime shiftStartTime;
    private BigDecimal liveSales;
    private int liveCovers;
    private long openOrdersCount;
    private Map<String, BigDecimal> paymentTotals;
}
