package com.example.backend.order.dto;

import java.time.LocalDateTime;
import java.util.UUID;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class KdsItemResponse {
    private UUID itemId;
    private UUID orderId;
    private String menuItemName;
    private Integer quantity;
    private String modifiers;
    private String course;
    private String orderType;
    private String tableNumber;
    private String status;
    private LocalDateTime kotFiredAt;
    private long minutesElapsed;
    private String colorCode; // GREEN, AMBER, RED
    private int priorityScore;
    private String voidReason;
    private LocalDateTime preparedAt;
    private UUID stationId;
    private String stationName;
    private String notes;
    private String customerName;
    private String customerPhone;
    private String deliveryPartnerName;
    private String deliveryPartnerPhone;
    private String orderStatus;
}
