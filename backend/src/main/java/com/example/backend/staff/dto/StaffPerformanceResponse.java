package com.example.backend.staff.dto;

import com.example.backend.staff.entity.StaffRole;
import java.math.BigDecimal;
import java.util.UUID;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StaffPerformanceResponse {
    private UUID staffId;
    private String name;
    private StaffRole role;
    private long totalOrders;
    private BigDecimal totalSales;
    private int coversServed;
    private long kotModifications;
    private long discountFrequency;
}
