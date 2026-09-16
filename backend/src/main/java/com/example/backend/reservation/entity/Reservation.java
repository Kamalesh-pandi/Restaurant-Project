package com.example.backend.reservation.entity;

import jakarta.persistence.*;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.UUID;
import lombok.*;

@Entity
@Table(name = "reservations")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Reservation {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "reservation_id")
    private UUID reservationId;

    @Column(name = "outlet_id")
    private UUID outletId;

    @Column(name = "guest_name", nullable = false)
    private String guestName;

    @Column(name = "guest_phone", nullable = false, length = 15)
    private String guestPhone;

    @Column(name = "party_size", nullable = false)
    private Integer partySize;

    @Column(nullable = false)
    private LocalDate date;

    @Column(nullable = false)
    private LocalTime time;

    @Column(name = "table_id")
    private UUID tableId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ReservationStatus status;

    @Column(name = "special_requests", columnDefinition = "text")
    private String specialRequests;

    @Column(name = "dietary_requirements", columnDefinition = "text")
    private String dietaryRequirements;

    @Column(name = "pre_order_items", columnDefinition = "text")
    private String preOrderItems;

    @Column(name = "is_online_booking", nullable = false)
    @Builder.Default
    private Boolean isOnlineBooking = false;

    @Column(name = "reminder_sent", nullable = false)
    @Builder.Default
    private Boolean reminderSent = false;

    @PrePersist
    public void prePersist() {
        if (this.reminderSent == null) {
            this.reminderSent = false;
        }
        if (this.isOnlineBooking == null) {
            this.isOnlineBooking = false;
        }
        if (this.status == null) {
            this.status = ReservationStatus.CONFIRMED;
        }
    }
}
