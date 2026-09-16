package com.example.backend.delivery.dto;

import com.example.backend.delivery.entity.AssignmentStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DeliveryAssignmentResponse {
    private UUID assignmentId;
    private UUID orderId;
    private String orderNumber;
    private UUID partnerId;
    private String partnerName;
    private String partnerPhone;
    private AssignmentStatus status;
    private LocalDateTime assignedAt;
    private LocalDateTime acceptedAt;
    private LocalDateTime pickedUpAt;
    private LocalDateTime deliveredAt;
    private String deliveryAddress;
    private String customerName;
    private String customerPhone;
    private String restaurantName;
    private String otpCode;
    private String deliveryNotes;
    private BigDecimal deliveryFee;
    private BigDecimal tipAmount;
    private String itemSummary;
    private Integer itemsCount;
    private Double deliveryLat;
    private Double deliveryLng;
    private LocalDateTime estimatedDeliveryTime;
    private BigDecimal totalOrderAmount;
}
