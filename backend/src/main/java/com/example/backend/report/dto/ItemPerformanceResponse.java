package com.example.backend.report.dto;

import java.util.List;
import java.util.Map;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ItemPerformanceResponse {
    private List<ItemSalesDto> top10ByUnits;
    private List<ItemSalesDto> bottom10ByUnits;
    private List<ItemSalesDto> top10ByRevenue;
    private Map<String, Long> sellThroughByTimeOfDay;
}
