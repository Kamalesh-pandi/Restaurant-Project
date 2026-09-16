package com.example.backend.bill.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RazorpayVerifyRequest {
    private UUID billId;
    private String razorpayPaymentId;
    private String razorpayOrderId;
    private String razorpaySignature;
}
