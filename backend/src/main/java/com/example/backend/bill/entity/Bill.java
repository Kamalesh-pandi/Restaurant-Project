package com.example.backend.bill.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;
import lombok.*;

@Entity
@Table(name = "bills")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Bill {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "bill_id")
    private UUID billId;

    @Column(name = "order_id", nullable = false)
    private UUID orderId;

    @Column(name = "bill_number", unique = true, nullable = false, length = 20)
    private String billNumber;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal subtotal;

    @Column(name = "round_off", precision = 6, scale = 2)
    @Builder.Default
    private BigDecimal roundOff = BigDecimal.ZERO;

    @Column(name = "tip_amount", precision = 6, scale = 2)
    @Builder.Default
    private BigDecimal tipAmount = BigDecimal.ZERO;

    @Column(name = "cash_received", precision = 10, scale = 2)
    private BigDecimal cashReceived;

    @Column(name = "change_given", precision = 10, scale = 2)
    private BigDecimal changeGiven;

    @Column(nullable = false, precision = 8, scale = 2)
    private BigDecimal cgst;

    @Column(nullable = false, precision = 8, scale = 2)
    private BigDecimal sgst;

    @Column(nullable = false, precision = 8, scale = 2)
    private BigDecimal discount;

    @Column(name = "loyalty_discount", nullable = false, precision = 6, scale = 2)
    @Builder.Default
    private BigDecimal loyaltyDiscount = BigDecimal.ZERO;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal total;

    @Column(name = "payment_method", columnDefinition = "text")
    private String paymentMethod;

    @Column(name = "is_settled", nullable = false)
    @Builder.Default
    private boolean isSettled = false;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "settled_at")
    private LocalDateTime settledAt;
}
