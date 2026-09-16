package com.example.backend.report.dto;

import java.util.List;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TableAnalyticsResponse {
    private double averageTableTurnTimeMinutes;
    private double coversPerTablePerDay;
    private List<String> peakOccupancyPeriods;
}
