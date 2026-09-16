package com.example.backend.bill.dto;

import java.math.BigDecimal;
import java.util.List;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SettleBillRequest {
    private List<BillPaymentSplitRequest> splits;
    private BigDecimal cashReceived;
    private BigDecimal changeGiven;
    private BigDecimal tipAmount;
    private String customerPhone;
}
