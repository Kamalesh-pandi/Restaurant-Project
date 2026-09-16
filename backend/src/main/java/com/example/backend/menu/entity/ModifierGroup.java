package com.example.backend.menu.entity;

import jakarta.persistence.*;
import java.util.UUID;
import lombok.*;

@Entity
@Table(name = "modifier_groups")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ModifierGroup {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "modifier_group_id")
    private UUID modifierGroupId;

    @Column(name = "item_id", nullable = false)
    private UUID menuItemId;

    @Column(nullable = false)
    private String name;

    @Column(name = "is_mandatory", nullable = false)
    @Builder.Default
    private boolean isMandatory = false;

    @Column(name = "min_selections")
    @Builder.Default
    private Integer minSelections = 0;

    @Column(name = "max_selections")
    @Builder.Default
    private Integer maxSelections = 1;
}
