package com.example.backend.chain.dto;

import java.math.BigDecimal;
import java.util.UUID;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OverrideMenuRequest {
    private UUID outletId;
    private UUID menuItemId;
    private BigDecimal overridePrice;
    private Boolean isAvailable;
    private Boolean isSpecial;
    private BigDecimal specialPrice;
}
