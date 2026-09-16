package com.example.backend.chain.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.util.UUID;
import lombok.*;

@Entity
@Table(name = "outlets")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Outlet {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "outlet_id")
    private UUID outletId;

    @Column(name = "brand_id")
    private UUID brandId;

    @Column(nullable = false)
    private String name;

    private String city;

    private String address;

    @Column(name = "is_franchise", nullable = false)
    @Builder.Default
    private Boolean isFranchise = false;

    @Column(name = "royalty_percentage", precision = 5, scale = 2)
    @Builder.Default
    private BigDecimal royaltyPercentage = BigDecimal.valueOf(5.00); // 5% default royalty

    @Column(name = "mystery_audit_active", nullable = false)
    @Builder.Default
    private Boolean mysteryAuditActive = false;

    @Column(name = "config_json", columnDefinition = "text")
    private String configJson;
}
