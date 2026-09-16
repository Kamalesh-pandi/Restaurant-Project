package com.example.backend.order.entity;

import jakarta.persistence.*;
import java.util.UUID;
import lombok.*;

@Entity
@Table(name = "orders")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Order {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "order_id")
    private UUID orderId;

    @Column(name = "outlet_id")
    private UUID outletId;

    @Column(name = "table_id")
    private UUID tableId;

    @Enumerated(EnumType.STRING)
    @Column(name = "order_type", nullable = false)
    private OrderType orderType;

    @Column(name = "token_number", length = 10)
    private String tokenNumber;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private OrderStatus status;

    @Column(name = "cashier_id")
    private UUID cashierId;

    @Column(name = "captain_id")
    private UUID captainId;

    @Builder.Default
    private Integer covers = 1;

    @Column(name = "customer_name", length = 100)
    private String customerName;

    @Column(name = "customer_phone", length = 20)
    private String customerPhone;

    @Column(name = "delivery_address", length = 500)
    private String deliveryAddress;

    @Column(name = "delivery_notes", length = 255)
    private String deliveryNotes;

    @Column(name = "delivery_lat")
    private Double deliveryLat;

    @Column(name = "delivery_lng")
    private Double deliveryLng;

    @Column(name = "delivery_otp", length = 10)
    private String deliveryOtp;

    @Column(name = "delivery_partner_id")
    private UUID deliveryPartnerId;

    @Column(name = "payment_method", length = 30)
    private String paymentMethod;

    @Column(name = "payment_status", length = 30)
    private String paymentStatus;

    @Column(name = "seated_at")
    private java.time.LocalDateTime seatedAt;

    @Column(name = "billed_at")
    private java.time.LocalDateTime billedAt;

    @Column(name = "kot_fired_at")
    private java.time.LocalDateTime kotFiredAt;

    @Column(name = "estimated_delivery_time")
    private java.time.LocalDateTime estimatedDeliveryTime;

    @Column(name = "is_training", nullable = false)
    @Builder.Default
    private Boolean isTraining = false;
}
