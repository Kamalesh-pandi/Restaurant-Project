package com.example.backend.menu.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalTime;
import java.util.UUID;
import lombok.*;

@Entity
@Table(name = "menu_items")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MenuItem {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "item_id")
    private UUID itemId;

    @Column(name = "outlet_id")
    private UUID outletId;

    @Column(nullable = false)
    private String name;

    @Column(columnDefinition = "text")
    private String description;

    @ManyToOne
    @JoinColumn(name = "category_id")
    private Category category;

    @Column(name = "image_url", columnDefinition = "text")
    private String imageUrl;

    @Column(name = "is_veg", nullable = false)
    @Builder.Default
    private boolean isVeg = true;

    @Column(nullable = false, precision = 8, scale = 2)
    private BigDecimal price;

    @Column(name = "price_takeaway", precision = 8, scale = 2)
    private BigDecimal priceTakeaway;

    @Column(name = "price_delivery", precision = 8, scale = 2)
    private BigDecimal priceDelivery;

    @Column(name = "gst_rate", nullable = false, precision = 5, scale = 2)
    @Builder.Default
    private BigDecimal gstRate = BigDecimal.valueOf(5.00);

    @Column(name = "hsn_code")
    private String hsnCode;

    @Column(name = "food_type", nullable = false)
    private String foodType;

    @Column(name = "is_available", nullable = false)
    @Builder.Default
    private boolean isAvailable = true;

    @Column(name = "is_special", nullable = false)
    @Builder.Default
    private boolean isSpecial = false;

    @Column(name = "special_price", precision = 8, scale = 2)
    private BigDecimal specialPrice;

    @Column(name = "available_from")
    private LocalTime availableFrom;

    @Column(name = "available_to")
    private LocalTime availableTo;

    @Column(name = "calories")
    private Integer calories;

    @Column(name = "allergens")
    private String allergens;

    @Column(name = "is_combo", nullable = false)
    @Builder.Default
    private boolean isCombo = false;

    @Column(name = "station_id")
    private UUID stationId;
}

