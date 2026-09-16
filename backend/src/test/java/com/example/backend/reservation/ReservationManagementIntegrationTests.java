package com.example.backend.reservation;

import com.example.backend.reservation.dto.ReservationAnalyticsResponse;
import com.example.backend.reservation.entity.Reservation;
import com.example.backend.reservation.entity.ReservationStatus;
import com.example.backend.reservation.repository.ReservationRepository;
import com.example.backend.reservation.service.ReservationScheduler;
import com.example.backend.reservation.service.ReservationService;
import com.example.backend.table.entity.RestaurantTable;
import com.example.backend.table.entity.TableStatus;
import com.example.backend.table.repository.RestaurantTableRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@Transactional
public class ReservationManagementIntegrationTests {

    @Autowired
    private ReservationService reservationService;

    @Autowired
    private ReservationScheduler reservationScheduler;

    @Autowired
    private ReservationRepository reservationRepository;

    @Autowired
    private RestaurantTableRepository tableRepository;

    private UUID outletId;
    private RestaurantTable table1;

    @BeforeEach
    public void setUp() {
        outletId = UUID.randomUUID();
        reservationRepository.deleteAll();
        tableRepository.deleteAll();

        // Seed Table
        table1 = RestaurantTable.builder()
                .outletId(outletId)
                .tableNumber("T10")
                .capacity(4)
                .status(TableStatus.AVAILABLE)
                .build();
        table1 = tableRepository.save(table1);
    }

    @Test
    public void testReservationCreationAndConfirmationSms() {
        Reservation reservation = Reservation.builder()
                .outletId(outletId)
                .guestName("Alice Green")
                .guestPhone("9876543210")
                .partySize(4)
                .date(LocalDate.now().plusDays(1))
                .time(LocalTime.of(19, 0))
                .specialRequests("Window seat")
                .dietaryRequirements("Vegan")
                .preOrderItems("Garlic Bread x 2")
                .tableId(table1.getTableId())
                .build();

        Reservation created = reservationService.createReservation(reservation);
        assertNotNull(created.getReservationId());
        assertEquals(ReservationStatus.CONFIRMED, created.getStatus());
        assertEquals("Vegan", created.getDietaryRequirements());
        assertEquals("Garlic Bread x 2", created.getPreOrderItems());
    }

    @Test
    public void testOnlineBookingAndGuestCancellation() {
        Reservation onlineRes = Reservation.builder()
                .outletId(outletId)
                .guestName("Bob SelfService")
                .guestPhone("9988776655")
                .partySize(2)
                .date(LocalDate.now().plusDays(2))
                .time(LocalTime.of(20, 0))
                .tableId(table1.getTableId())
                .build();

        Reservation created = reservationService.createOnlineReservation(onlineRes);
        assertTrue(created.getIsOnlineBooking());

        // Cancel by guest using link
        Reservation cancelled = reservationService.cancelReservationByGuest(created.getReservationId());
        assertEquals(ReservationStatus.CANCELLED, cancelled.getStatus());
    }

    @Test
    public void test2HourReminderAndNoShowHoldRelease() {
        LocalDate today = LocalDate.now();
        LocalTime pastTime = LocalTime.now().minusMinutes(20);

        // Seed reservation that started 20 minutes ago (past 15-minute no-show window)
        Reservation expiredRes = Reservation.builder()
                .outletId(outletId)
                .guestName("Late Guest")
                .guestPhone("9123456789")
                .partySize(4)
                .date(today)
                .time(pastTime)
                .tableId(table1.getTableId())
                .status(ReservationStatus.CONFIRMED)
                .build();
        expiredRes = reservationRepository.save(expiredRes);

        table1.setStatus(TableStatus.RESERVED);
        tableRepository.save(table1);

        // Run scheduler
        reservationScheduler.checkAndReleaseReservations();

        Reservation fetched = reservationRepository.findById(expiredRes.getReservationId()).orElseThrow();
        assertEquals(ReservationStatus.NO_SHOW, fetched.getStatus());

        RestaurantTable updatedTable = tableRepository.findById(table1.getTableId()).orElseThrow();
        assertEquals(TableStatus.AVAILABLE, updatedTable.getStatus());
    }

    @Test
    public void testReservationAnalytics() {
        Reservation r1 = Reservation.builder()
                .outletId(outletId)
                .guestName("Guest 1")
                .guestPhone("1111111111")
                .partySize(2)
                .date(LocalDate.now())
                .time(LocalTime.of(19, 0))
                .status(ReservationStatus.ARRIVED)
                .build();
        reservationRepository.save(r1);

        Reservation r2 = Reservation.builder()
                .outletId(outletId)
                .guestName("Guest 2")
                .guestPhone("2222222222")
                .partySize(2)
                .date(LocalDate.now())
                .time(LocalTime.of(19, 0))
                .status(ReservationStatus.NO_SHOW)
                .build();
        reservationRepository.save(r2);

        ReservationAnalyticsResponse analytics = reservationService.getReservationAnalytics();
        assertEquals(2, analytics.getTotalBookings());
        assertEquals(1, analytics.getCompletedBookings());
        assertEquals(1, analytics.getNoShowCount());
        assertEquals(50.0, analytics.getBookingConversionRate());
        assertEquals(50.0, analytics.getNoShowRate());
        assertFalse(analytics.getPeakBookingTimes().isEmpty());
    }
}
