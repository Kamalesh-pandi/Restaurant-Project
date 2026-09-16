package com.example.backend.order.dto;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class KdsPerformanceResponse {
    private int currentOrdersCount;
    private double averagePrepTimeMinutes;
    private int itemsSoldCount;
}
