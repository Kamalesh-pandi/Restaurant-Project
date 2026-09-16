package com.example.backend.reservation.controller;

import com.example.backend.reservation.dto.ReservationAnalyticsResponse;
import com.example.backend.reservation.entity.Reservation;
import com.example.backend.reservation.entity.ReservationStatus;
import com.example.backend.reservation.service.ReservationService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/reservations")
public class ReservationController {

    private final ReservationService reservationService;

    public ReservationController(ReservationService reservationService) {
        this.reservationService = reservationService;
    }

    @GetMapping
    public ResponseEntity<List<Reservation>> getAllReservations() {
        return ResponseEntity.ok(reservationService.getAllReservations());
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('CASHIER', 'CAPTAIN', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Reservation> createReservation(@Valid @RequestBody Reservation reservation) {
        return ResponseEntity.status(HttpStatus.CREATED).body(reservationService.createReservation(reservation));
    }

    @PostMapping("/online")
    public ResponseEntity<Reservation> createOnlineReservation(@Valid @RequestBody Reservation reservation) {
        return ResponseEntity.status(HttpStatus.CREATED).body(reservationService.createOnlineReservation(reservation));
    }

    @PostMapping("/{id}/cancel-by-guest")
    public ResponseEntity<Reservation> cancelReservationByGuest(@PathVariable UUID id) {
        return ResponseEntity.ok(reservationService.cancelReservationByGuest(id));
    }

    @PostMapping("/{id}/cancel")
    @PreAuthorize("hasAnyRole('CASHIER', 'CAPTAIN', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Reservation> cancelReservationByRestaurant(@PathVariable UUID id) {
        return ResponseEntity.ok(reservationService.cancelReservationByRestaurant(id));
    }

    @PutMapping("/{id}/status")
    @PreAuthorize("hasAnyRole('CASHIER', 'CAPTAIN', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Reservation> updateStatus(@PathVariable UUID id, @RequestParam ReservationStatus status) {
        return ResponseEntity.ok(reservationService.updateReservationStatus(id, status));
    }

    @GetMapping("/analytics")
    @PreAuthorize("hasAnyRole('CASHIER', 'CAPTAIN', 'MANAGER', 'ADMIN')")
    public ResponseEntity<ReservationAnalyticsResponse> getReservationAnalytics() {
        return ResponseEntity.ok(reservationService.getReservationAnalytics());
    }
}
