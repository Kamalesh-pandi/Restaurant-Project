package com.example.backend.chain.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.util.UUID;
import lombok.*;

@Entity
@Table(name = "outlet_menu_overrides")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OutletMenuOverride {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "outlet_id", nullable = false)
    private UUID outletId;

    @Column(name = "menu_item_id", nullable = false)
    private UUID menuItemId;

    @Column(name = "override_price", precision = 8, scale = 2)
    private BigDecimal overridePrice;

    @Column(name = "is_available")
    private Boolean isAvailable;

    @Column(name = "is_special")
    private Boolean isSpecial;

    @Column(name = "special_price", precision = 8, scale = 2)
    private BigDecimal specialPrice;
}
