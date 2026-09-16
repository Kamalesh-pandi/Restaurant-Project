package com.example.backend.customer.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.UUID;
import lombok.*;

@Entity
@Table(name = "customer_addresses")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CustomerAddress {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "address_id")
    private UUID addressId;

    @Column(name = "customer_id", nullable = false)
    private UUID customerId;

    @Column(length = 50, nullable = false)
    private String label; // e.g. "Home", "Work", "Other"

    @Column(name = "house_no", length = 100)
    private String houseNo; // e.g. "Flat 402, Building A"

    @Column(length = 255)
    private String street; // e.g. "12th Main Road, Indiranagar"

    @Column(length = 150)
    private String landmark; // e.g. "Near Metro Station"

    @Column(length = 100)
    private String city;

    @Column(length = 100)
    private String state;

    @Column(length = 20)
    private String pincode;

    private Double latitude;

    private Double longitude;

    @Column(name = "full_address", length = 500)
    private String fullAddress;

    @Column(name = "is_default", nullable = false)
    @Builder.Default
    private Boolean isDefault = false;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
        if (this.isDefault == null) {
            this.isDefault = false;
        }
    }

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }
}
