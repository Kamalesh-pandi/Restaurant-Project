package com.example.backend.inventory.dto;

import java.math.BigDecimal;
import java.util.UUID;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DailyStockSetupRequest {
    private UUID ingredientId;
    private BigDecimal openingStock;
}
