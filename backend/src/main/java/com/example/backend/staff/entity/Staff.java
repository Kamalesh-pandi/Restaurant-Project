package com.example.backend.staff.entity;

import jakarta.persistence.*;
import java.util.UUID;
import lombok.*;

@Entity
@Table(name = "staff")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Staff {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "staff_id")
    private UUID staffId;

    @Column(name = "outlet_id")
    private UUID outletId;

    @Column(nullable = false, unique = true)
    private String name;

    @Column(name = "pin_hash", nullable = false, length = 60)
    private String pinHash;

    @Column(length = 100)
    private String email;

    @Column(name = "phone_number", length = 30)
    private String phoneNumber;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private StaffRole role;

    @Column(length = 50)
    private String section;

    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private boolean isActive = true;

    @Column(name = "employment_type", length = 20)
    @Builder.Default
    private String employmentType = "FULL_TIME";
}
