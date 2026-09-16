package com.example.backend.inventory.entity;

import jakarta.persistence.*;
import java.util.UUID;
import lombok.*;

@Entity
@Table(name = "suppliers")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Supplier {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "supplier_id")
    private UUID supplierId;

    @Column(nullable = false)
    private String name;

    private String contact;

    @Column(name = "items_supplied")
    private String itemsSupplied; // Comma-separated ingredient names/IDs

    @Column(name = "price_history", columnDefinition = "text")
    private String priceHistory;
}
