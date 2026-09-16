package com.example.backend.menu.entity;

import jakarta.persistence.*;
import java.util.UUID;
import lombok.*;

@Entity
@Table(name = "combo_components")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ComboComponent {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "component_id")
    private UUID componentId;

    @Column(name = "combo_item_id", nullable = false)
    private UUID comboItemId;

    @Column(name = "component_item_id", nullable = false)
    private UUID componentItemId;

    @Column(nullable = false)
    @Builder.Default
    private Integer quantity = 1;
}
