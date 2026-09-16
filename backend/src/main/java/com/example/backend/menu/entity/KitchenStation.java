package com.example.backend.menu.entity;

import jakarta.persistence.*;
import java.util.UUID;
import lombok.*;

@Entity
@Table(name = "kitchen_stations")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class KitchenStation {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false, unique = true)
    private String name;
}
