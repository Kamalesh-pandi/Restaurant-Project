package com.example.backend.customer.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;
import lombok.*;

@Entity
@Table(name = "customer_visits")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CustomerVisit {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "customer_id", nullable = false)
    private UUID customerId;

    @Column(name = "order_id", nullable = false)
    private UUID orderId;

    @Column(name = "visit_date", nullable = false)
    private LocalDateTime visitDate;

    @Column(name = "table_number")
    private String tableNumber;

    @Column(name = "items_ordered", columnDefinition = "text")
    private String itemsOrdered; // Comma-separated names of items

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal spend;

    private Integer rating; // 1-5 stars feedback

    @Column(name = "feedback_comment", columnDefinition = "text")
    private String feedbackComment;
}
