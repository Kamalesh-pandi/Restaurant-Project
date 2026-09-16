package com.example.backend.customer.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.util.UUID;
import lombok.*;

@Entity
@Table(name = "cart_sessions")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CartSession {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id")
    private UUID id;

    @Column(name = "phone", unique = true, nullable = false)
    private String phone;

    @Column(name = "applied_coupon")
    private String appliedCoupon;

    @Column(name = "discount_amount", precision = 10, scale = 2)
    @Builder.Default
    private BigDecimal discountAmount = BigDecimal.ZERO;
}
