package com.example.backend.report.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;
import lombok.*;

@Entity
@Table(name = "day_end_reports")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DayEndReport {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "report_id")
    private UUID reportId;

    @Column(name = "outlet_id")
    private UUID outletId;

    @Column(name = "report_date", nullable = false)
    private LocalDate reportDate;

    @Column(name = "total_sales", nullable = false, precision = 12, scale = 2)
    private BigDecimal totalSales;

    @Column(name = "total_covers", nullable = false)
    private Integer totalCovers;

    @Column(name = "total_discounts", nullable = false, precision = 10, scale = 2)
    private BigDecimal totalDiscounts;

    @Column(name = "total_voids", nullable = false, precision = 10, scale = 2)
    private BigDecimal totalVoids;

    @Column(name = "cash_collected", nullable = false, precision = 10, scale = 2)
    private BigDecimal cashCollected;

    @Column(name = "card_collected", nullable = false, precision = 10, scale = 2)
    private BigDecimal cardCollected;

    @Column(name = "upi_collected", nullable = false, precision = 10, scale = 2)
    private BigDecimal upiCollected;

    @Column(name = "total_complimentary_value", precision = 10, scale = 2)
    @Builder.Default
    private BigDecimal totalComplimentaryValue = BigDecimal.ZERO;

    @Column(name = "wallet_collected", nullable = false, precision = 10, scale = 2)
    @Builder.Default
    private BigDecimal walletCollected = BigDecimal.ZERO;

    @Column(name = "total_tips", nullable = false, precision = 10, scale = 2)
    @Builder.Default
    private BigDecimal totalTips = BigDecimal.ZERO;

    @Column(name = "generated_by")
    private UUID generatedBy;

    @Column(name = "generated_at", nullable = false)
    private LocalDateTime generatedAt;
}
