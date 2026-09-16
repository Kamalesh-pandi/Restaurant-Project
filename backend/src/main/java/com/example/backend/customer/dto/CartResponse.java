package com.example.backend.customer.dto;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CartResponse {
    private String phone;
    private List<Map<String, Object>> cartItems;
    private String appliedCoupon;
    private BigDecimal discountAmount;
}
