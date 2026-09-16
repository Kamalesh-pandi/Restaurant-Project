package com.example.backend.customer.dto;

import com.example.backend.order.entity.OrderType;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class DirectOrderRequest {
    private UUID outletId;
    private String customerName;
    private String customerPhone;
    private String customerEmail;
    private OrderType orderType; // DELIVERY or TAKEAWAY or DIRECT_ONLINE
    private UUID addressId;
    private String deliveryAddress;
    private Double deliveryLat;
    private Double deliveryLng;
    private String deliveryNotes;
    private String paymentMethod; // COD, ONLINE, RAZORPAY
    private List<ItemRequest> items;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ItemRequest {
        private UUID menuItemId;
        private Integer quantity;
        private String modifiers;
    }
}
