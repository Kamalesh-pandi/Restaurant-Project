package com.example.backend.inventory.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;
import lombok.*;

@Entity
@Table(name = "inventory_items")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class InventoryItem {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "ingredient_id")
    private UUID ingredientId;

    @Column(name = "outlet_id")
    private UUID outletId;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false, length = 20)
    private String unit;

    @Column(name = "current_stock", nullable = false, precision = 10, scale = 3)
    private BigDecimal currentStock;

    @Column(name = "reorder_level", nullable = false, precision = 10, scale = 3)
    private BigDecimal reorderLevel;

    @Column(name = "cost_price", nullable = false, precision = 8, scale = 2)
    private BigDecimal costPrice;

    @Column(name = "last_updated_at")
    private LocalDateTime lastUpdatedAt;
}
