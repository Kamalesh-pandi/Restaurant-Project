package com.example.backend.reservation.service;

import com.example.backend.reservation.entity.Reservation;
import com.example.backend.reservation.entity.ReservationStatus;
import com.example.backend.reservation.repository.ReservationRepository;
import com.example.backend.table.entity.RestaurantTable;
import com.example.backend.table.entity.TableStatus;
import com.example.backend.table.service.TableService;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Component
public class ReservationScheduler {

    private final ReservationRepository reservationRepository;
    private final TableService tableService;
    private final ReservationService reservationService;

    public ReservationScheduler(ReservationRepository reservationRepository, TableService tableService, ReservationService reservationService) {
        this.reservationRepository = reservationRepository;
        this.tableService = tableService;
        this.reservationService = reservationService;
    }

    @Scheduled(cron = "0 * * * * *") // Run every minute
    @Transactional
    public void checkAndReleaseReservations() {
        reservationService.send2HourReminders();

        LocalDate today = LocalDate.now();
        LocalDateTime now = LocalDateTime.now();

        List<Reservation> confirmedReservations = reservationRepository.findByStatus(ReservationStatus.CONFIRMED);
        for (Reservation res : confirmedReservations) {
            LocalDateTime reservationDateTime = LocalDateTime.of(res.getDate(), res.getTime());

            // 1. Release hold if guest doesn't arrive within 15 minutes
            if (reservationDateTime.plusMinutes(15).isBefore(now)) {
                res.setStatus(ReservationStatus.NO_SHOW);
                reservationRepository.save(res);
                if (res.getTableId() != null) {
                    RestaurantTable table = tableService.getTableById(res.getTableId());
                    if (table.getStatus() == TableStatus.RESERVED) {
                        tableService.releaseTable(res.getTableId());
                    }
                }
            }
            // 2. Lock table as RESERVED (yellow) 30 minutes before reservation start time up to 15 mins after
            else if (res.getDate().equals(today) 
                    && now.isAfter(reservationDateTime.minusMinutes(30)) 
                    && now.isBefore(reservationDateTime.plusMinutes(15))) {
                if (res.getTableId() != null) {
                    RestaurantTable table = tableService.getTableById(res.getTableId());
                    if (table.getStatus() == TableStatus.AVAILABLE) {
                        tableService.updateTableStatus(res.getTableId(), TableStatus.RESERVED);
                    }
                }
            }
        }
    }
}
