package com.example.backend.customer.dto;

import com.example.backend.order.entity.OrderStatus;
import com.example.backend.order.entity.OrderType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CustomerOrderTrackingResponse {
    private UUID orderId;
    private OrderType orderType;
    private OrderStatus status;
    private String customerName;
    private String customerPhone;
    private String deliveryAddress;
    private String deliveryNotes;
    private String deliveryOtp;
    private String paymentMethod;
    private String paymentStatus;
    private LocalDateTime estimatedDeliveryTime;

    // Live Delivery Partner Details
    private UUID partnerId;
    private String partnerName;
    private String partnerPhone;
    private String partnerVehicleNumber;
    private Double partnerCurrentLat;
    private Double partnerCurrentLng;
    private LocalDateTime partnerLastLocationUpdate;

    private List<TrackedItem> items;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class TrackedItem {
        private String menuItemName;
        private Integer quantity;
        private BigDecimal price;
    }
}
