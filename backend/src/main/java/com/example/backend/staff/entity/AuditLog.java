package com.example.backend.staff.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;
import lombok.*;

@Entity
@Table(name = "audit_logs")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AuditLog {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false, length = 50)
    private String action; // DISCOUNT, COMPLIMENTARY, VOID

    @Column(name = "order_id")
    private UUID orderId;

    @Column(precision = 10, scale = 2)
    private BigDecimal amount;

    @Column(columnDefinition = "text")
    private String reason;

    @Column(name = "manager_id")
    private UUID managerId;

    @Column(name = "manager_name")
    private String managerName;

    @Column(nullable = false)
    private LocalDateTime timestamp;
}
