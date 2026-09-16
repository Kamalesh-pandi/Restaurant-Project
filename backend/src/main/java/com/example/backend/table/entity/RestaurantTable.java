package com.example.backend.table.entity;

import jakarta.persistence.*;
import java.util.UUID;
import lombok.*;

@Entity
@Table(name = "tables")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RestaurantTable {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "table_id")
    private UUID tableId;

    @Column(name = "outlet_id")
    private UUID outletId;

    private String section;

    @Column(name = "table_number", nullable = false, length = 10)
    private String tableNumber;

    private Integer capacity;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private TableStatus status;

    @Column(name = "current_order_id")
    private UUID currentOrderId;

    @Column(name = "x_pos")
    private Integer xPos;

    @Column(name = "y_pos")
    private Integer yPos;

    @Column(name = "parent_table_id")
    private UUID parentTableId;
}
