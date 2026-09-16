package com.example.backend.inventory.dto;

import java.math.BigDecimal;
import java.util.UUID;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DailyStockCloseRequest {
    private UUID ingredientId;
    private BigDecimal actualClosing;
}
