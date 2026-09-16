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
public class CustomerOrderHistoryResponse {
    private UUID orderId;
    private UUID outletId;
    private UUID tableId;
    private String tableNumber;
    private OrderType orderType;
    private OrderStatus status;
    private String orderStatus; // String alias for compatibility

    private String customerName;
    private String customerPhone;
    private String deliveryAddress;
    private String deliveryNotes;
    private String deliveryOtp;
    private String paymentMethod;
    private String paymentStatus;

    private LocalDateTime estimatedDeliveryTime;
    private LocalDateTime createdAt;

    private BigDecimal subtotal;
    private BigDecimal gstAmount;
    private BigDecimal deliveryFee;
    private BigDecimal discount;
    private BigDecimal grandTotal;
    private BigDecimal totalAmount; // Alias for compatibility

    private List<CustomerOrderTrackingResponse.TrackedItem> items;
}
