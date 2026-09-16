package com.example.backend.bill.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CashDrawerReconciliation {
    private LocalDate date;
    private BigDecimal startingCash;
    private BigDecimal cashCollected;
    private BigDecimal expectedCashInDrawer;
}
