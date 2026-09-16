package com.example.backend.inventory.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;
import lombok.*;

@Entity
@Table(name = "daily_stock_sheets")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DailyStockSheet {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "ingredient_id", nullable = false)
    private UUID ingredientId;

    @Column(name = "stock_date", nullable = false)
    private LocalDate stockDate;

    @Column(name = "opening_stock", nullable = false, precision = 10, scale = 3)
    private BigDecimal openingStock;

    @Column(name = "theoretical_consumption", nullable = false, precision = 10, scale = 3)
    @Builder.Default
    private BigDecimal theoreticalConsumption = BigDecimal.ZERO;

    @Column(name = "received_stock", nullable = false, precision = 10, scale = 3)
    @Builder.Default
    private BigDecimal receivedStock = BigDecimal.ZERO;

    @Column(name = "theoretical_closing", nullable = false, precision = 10, scale = 3)
    @Builder.Default
    private BigDecimal theoreticalClosing = BigDecimal.ZERO;

    @Column(name = "actual_closing", precision = 10, scale = 3)
    private BigDecimal actualClosing;

    @Column(precision = 10, scale = 3)
    private BigDecimal variance;
}
