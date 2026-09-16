package com.example.backend.customer.dto;

import java.util.Map;
import java.util.UUID;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CartItemRequest {
    private String phone;
    private String cartItemId;
    private UUID menuItemId;
    private Map<String, Object> item;
    private Integer quantity;
    private Object selectedModifiers;
    private String specialInstructions;
}
