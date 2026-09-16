package com.example.backend.chain.dto;

import java.math.BigDecimal;
import java.util.UUID;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OutletComparisonResponse {
    private UUID outletId;
    private String outletName;
    private String city;
    private Boolean isFranchise;
    private BigDecimal gmv;
    private int totalCovers;
    private long totalOrders;
    private BigDecimal averageOrderValue;
    private BigDecimal calculatedRoyalty;
    private Boolean mysteryAuditActive;
}
