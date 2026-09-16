package com.example.backend.chain.dto;

import java.math.BigDecimal;
import java.util.List;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ConsolidatedChainReportResponse {
    private BigDecimal chainTotalGmv;
    private int chainTotalCovers;
    private long chainTotalOrders;
    private BigDecimal chainAverageOrderValue;
    private List<String> topSellingItems;
}
