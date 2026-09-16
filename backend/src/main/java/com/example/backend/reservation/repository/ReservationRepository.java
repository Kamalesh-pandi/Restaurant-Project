package com.example.backend.reservation.repository;

import com.example.backend.reservation.entity.Reservation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.example.backend.reservation.entity.ReservationStatus;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Repository
public interface ReservationRepository extends JpaRepository<Reservation, UUID> {
    List<Reservation> findByStatus(ReservationStatus status);
    List<Reservation> findByStatusAndDate(ReservationStatus status, LocalDate date);
    List<Reservation> findByGuestPhoneOrderByDateDescTimeDesc(String guestPhone);
}
