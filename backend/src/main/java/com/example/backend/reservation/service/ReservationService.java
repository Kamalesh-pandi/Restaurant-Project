package com.example.backend.reservation.service;

import com.example.backend.reservation.dto.ReservationAnalyticsResponse;
import com.example.backend.reservation.entity.Reservation;
import com.example.backend.reservation.entity.ReservationStatus;
import com.example.backend.reservation.repository.ReservationRepository;
import com.example.backend.table.entity.RestaurantTable;
import com.example.backend.table.entity.TableStatus;
import com.example.backend.table.service.TableService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class ReservationService {

    private final ReservationRepository reservationRepository;
    private final TableService tableService;

    public ReservationService(ReservationRepository reservationRepository, TableService tableService) {
        this.reservationRepository = reservationRepository;
        this.tableService = tableService;
    }

    public List<Reservation> getAllReservations() {
        return reservationRepository.findAll();
    }

    public Reservation getReservationById(UUID id) {
        return reservationRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Reservation not found"));
    }

    @Transactional
    public Reservation createReservation(Reservation reservation) {
        if (reservation.getOutletId() == null) {
            reservation.setOutletId(UUID.randomUUID());
        }
        if (reservation.getStatus() == null) {
            reservation.setStatus(ReservationStatus.CONFIRMED);
        }
        if (reservation.getReminderSent() == null) {
            reservation.setReminderSent(false);
        }
        if (reservation.getIsOnlineBooking() == null) {
            reservation.setIsOnlineBooking(false);
        }
        if (reservation.getTableId() != null) {
            try {
                tableService.updateTableStatus(reservation.getTableId(), TableStatus.RESERVED);
            } catch (Exception e) {
                System.err.println("Warning: could not update table status: " + e.getMessage());
            }
        }
        Reservation saved = reservationRepository.save(reservation);
        sendConfirmationSms(saved);
        return saved;
    }

    public List<Reservation> getReservationsByPhone(String phone) {
        if (phone == null || phone.trim().isEmpty()) {
            return Collections.emptyList();
        }
        return reservationRepository.findByGuestPhoneOrderByDateDescTimeDesc(phone.trim());
    }

    @Transactional
    public Reservation createOnlineReservation(Reservation reservation) {
        reservation.setIsOnlineBooking(true);
        return createReservation(reservation);
    }

    private void sendConfirmationSms(Reservation reservation) {
        String cancelLink = "http://deluxediner.com/reservations/cancel/" + reservation.getReservationId();
        System.out.println(String.format("[CONFIRMATION SMS] Sent to %s (+91%s): \"Your reservation for party of %d on %s at %s is CONFIRMED. Manage or cancel booking via: %s\"",
                reservation.getGuestName(), reservation.getGuestPhone(), reservation.getPartySize(),
                reservation.getDate(), reservation.getTime(), cancelLink));
    }

    @Transactional
    public Reservation updateReservationStatus(UUID id, ReservationStatus status) {
        Reservation reservation = getReservationById(id);
        ReservationStatus oldStatus = reservation.getStatus();
        reservation.setStatus(status);
        Reservation saved = reservationRepository.save(reservation);

        if (reservation.getTableId() != null) {
            if (status == ReservationStatus.ARRIVED) {
                tableService.updateTableStatus(reservation.getTableId(), TableStatus.OCCUPIED);
            } else if ((status == ReservationStatus.CANCELLED || status == ReservationStatus.NO_SHOW) 
                    && oldStatus == ReservationStatus.CONFIRMED) {
                RestaurantTable table = tableService.getTableById(reservation.getTableId());
                if (table.getStatus() == TableStatus.RESERVED) {
                    tableService.releaseTable(reservation.getTableId());
                }
            }
        }
        return saved;
    }

    @Transactional
    public Reservation cancelReservationByGuest(UUID id) {
        System.out.println(String.format("[GUEST CANCELLATION] Reservation %s cancelled via SMS link by guest.", id));
        return updateReservationStatus(id, ReservationStatus.CANCELLED);
    }

    @Transactional
    public Reservation cancelReservationByRestaurant(UUID id) {
        System.out.println(String.format("[RESTAURANT CANCELLATION] Reservation %s cancelled from dashboard.", id));
        return updateReservationStatus(id, ReservationStatus.CANCELLED);
    }

    @Transactional
    public void send2HourReminders() {
        LocalDate today = LocalDate.now();
        LocalTime nowTime = LocalTime.now();
        LocalTime targetTime = nowTime.plusHours(2);

        List<Reservation> todayConfirmed = reservationRepository.findByStatusAndDate(ReservationStatus.CONFIRMED, today);
        for (Reservation res : todayConfirmed) {
            if (!res.getReminderSent() && res.getTime().isBefore(targetTime) && !res.getTime().isBefore(nowTime)) {
                res.setReminderSent(true);
                reservationRepository.save(res);
                System.out.println(String.format("[REMINDER SMS] Sent to %s (+91%s): \"Reminder: Your table reservation for %d is today at %s. See you soon!\"",
                        res.getGuestName(), res.getGuestPhone(), res.getPartySize(), res.getTime()));
            }
        }
    }

    public ReservationAnalyticsResponse getReservationAnalytics() {
        List<Reservation> all = reservationRepository.findAll();
        long total = all.size();
        long noShow = all.stream().filter(r -> r.getStatus() == ReservationStatus.NO_SHOW).count();
        long cancelled = all.stream().filter(r -> r.getStatus() == ReservationStatus.CANCELLED).count();
        long completed = all.stream().filter(r -> r.getStatus() == ReservationStatus.ARRIVED).count();

        double conversionRate = total == 0 ? 0.0 : ((double) completed / total) * 100.0;
        double noShowRate = total == 0 ? 0.0 : ((double) noShow / total) * 100.0;

        // Peak booking times calculation
        Map<String, Long> timeCounts = new HashMap<>();
        for (Reservation r : all) {
            String hourKey = r.getTime().getHour() + ":00";
            timeCounts.put(hourKey, timeCounts.getOrDefault(hourKey, 0L) + 1);
        }

        List<String> peakTimes = timeCounts.entrySet().stream()
                .sorted((e1, e2) -> Long.compare(e2.getValue(), e1.getValue()))
                .limit(3)
                .map(Map.Entry::getKey)
                .collect(Collectors.toList());

        return ReservationAnalyticsResponse.builder()
                .totalBookings(total)
                .completedBookings(completed)
                .noShowCount(noShow)
                .cancelledCount(cancelled)
                .bookingConversionRate(conversionRate)
                .noShowRate(noShowRate)
                .peakBookingTimes(peakTimes)
                .build();
    }
}
