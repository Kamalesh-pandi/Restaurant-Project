package com.example.backend.report.dto;

import java.math.BigDecimal;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ItemSalesDto {
    private String itemName;
    private int unitsSold;
    private BigDecimal totalRevenue;
}
