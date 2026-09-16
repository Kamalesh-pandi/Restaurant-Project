package com.example.backend.customer.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.util.UUID;
import lombok.*;

@Entity
@Table(name = "cart_items")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CartItem {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id")
    private UUID id;

    @Column(name = "cart_item_id")
    private String cartItemId;

    @Column(name = "phone", nullable = false)
    private String phone;

    @Column(name = "menu_item_id")
    private UUID menuItemId;

    @Column(name = "item_name")
    private String itemName;

    @Column(name = "item_description", length = 1000)
    private String itemDescription;

    @Column(name = "item_price", precision = 10, scale = 2)
    private BigDecimal itemPrice;

    @Column(name = "item_image_url")
    private String itemImageUrl;

    @Column(name = "is_veg")
    private Boolean isVeg;

    @Column(name = "quantity", nullable = false)
    @Builder.Default
    private Integer quantity = 1;

    @Column(name = "selected_modifiers", length = 1000)
    private String selectedModifiers;

    @Column(name = "special_instructions", length = 500)
    private String specialInstructions;
}
