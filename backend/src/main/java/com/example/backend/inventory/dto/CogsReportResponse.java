package com.example.backend.inventory.dto;

import java.math.BigDecimal;
import java.util.UUID;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CogsReportResponse {
    private UUID menuItemId;
    private String menuItemName;
    private BigDecimal menuItemPrice;
    private BigDecimal ingredientCost; // COGS
    private BigDecimal grossMarginPercentage;
}
