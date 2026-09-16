package com.example.backend.bill.dto;

import java.math.BigDecimal;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BillPaymentSplitRequest {
    private String paymentMethod;
    private BigDecimal amount;
    private String transactionReference;
}
