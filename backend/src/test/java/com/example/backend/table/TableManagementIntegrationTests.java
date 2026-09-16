package com.example.backend.table;

import com.example.backend.order.entity.Order;
import com.example.backend.order.entity.OrderStatus;
import com.example.backend.order.entity.OrderType;
import com.example.backend.order.repository.OrderRepository;
import com.example.backend.reservation.entity.Reservation;
import com.example.backend.reservation.entity.ReservationStatus;
import com.example.backend.reservation.repository.ReservationRepository;
import com.example.backend.reservation.service.ReservationScheduler;
import com.example.backend.staff.entity.Staff;
import com.example.backend.staff.entity.StaffRole;
import com.example.backend.staff.repository.StaffRepository;
import com.example.backend.table.entity.*;
import com.example.backend.table.repository.RestaurantTableRepository;
import com.example.backend.table.repository.WaitlistRepository;
import com.example.backend.table.service.TableService;
import com.example.backend.table.service.WaitlistService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.Collections;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@Transactional
public class TableManagementIntegrationTests {

    @Autowired
    private TableService tableService;

    @Autowired
    private WaitlistService waitlistService;

    @Autowired
    private RestaurantTableRepository tableRepository;

    @Autowired
    private WaitlistRepository waitlistRepository;

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private StaffRepository staffRepository;

    @Autowired
    private ReservationRepository reservationRepository;

    @Autowired
    private ReservationScheduler reservationScheduler;

    private UUID outletId;

    @BeforeEach
    public void setUp() {
        outletId = UUID.randomUUID();
        tableRepository.deleteAll();
        waitlistRepository.deleteAll();
        orderRepository.deleteAll();
        staffRepository.deleteAll();
        reservationRepository.deleteAll();
    }

    @Test
    public void testTableCRUDAndLayoutEditor() {
        RestaurantTable table = RestaurantTable.builder()
                .outletId(outletId)
                .tableNumber("T1")
                .capacity(4)
                .section("indoor")
                .xPos(10)
                .yPos(20)
                .status(TableStatus.AVAILABLE)
                .build();

        RestaurantTable created = tableService.createTable(table);
        assertNotNull(created.getTableId());
        assertEquals("T1", created.getTableNumber());

        created.setTableNumber("T1-Mod");
        created.setXPos(15);
        RestaurantTable updated = tableService.updateTable(created.getTableId(), created);
        assertEquals("T1-Mod", updated.getTableNumber());
        assertEquals(15, updated.getXPos());

        tableService.deleteTable(created.getTableId());
        assertThrows(RuntimeException.class, () -> tableService.getTableById(created.getTableId()));
    }

    @Test
    public void testWaiterSectionFiltering() {
        RestaurantTable t1 = tableService.createTable(RestaurantTable.builder()
                .outletId(outletId)
                .tableNumber("T1")
                .capacity(2)
                .section("indoor")
                .build());

        RestaurantTable t2 = tableService.createTable(RestaurantTable.builder()
                .outletId(outletId)
                .tableNumber("T2")
                .capacity(4)
                .section("outdoor")
                .build());

        Staff waiter = Staff.builder()
                .outletId(outletId)
                .name("WaiterJohn")
                .pinHash("somehash")
                .role(StaffRole.CAPTAIN)
                .section("indoor")
                .isActive(true)
                .build();
        staffRepository.save(waiter);

        List<RestaurantTable> johnsTables = tableService.getTablesForStaff("WaiterJohn", outletId);
        assertEquals(1, johnsTables.size());
        assertEquals("T1", johnsTables.get(0).getTableNumber());

        List<RestaurantTable> allTables = tableService.getTablesForStaff("ManagerBob", outletId);
        assertEquals(2, allTables.size());
    }

    @Test
    public void testTableMergingAndUnmerging() {
        RestaurantTable primary = tableService.createTable(RestaurantTable.builder()
                .outletId(outletId)
                .tableNumber("P1")
                .capacity(2)
                .section("indoor")
                .build());

        RestaurantTable secondary = tableService.createTable(RestaurantTable.builder()
                .outletId(outletId)
                .tableNumber("S1")
                .capacity(2)
                .section("indoor")
                .build());

        tableService.mergeTables(primary.getTableId(), Collections.singletonList(secondary.getTableId()));

        RestaurantTable updatedSec = tableService.getTableById(secondary.getTableId());
        assertEquals(primary.getTableId(), updatedSec.getParentTableId());

        Order order = Order.builder()
                .outletId(outletId)
                .tableId(primary.getTableId())
                .orderType(OrderType.DINE_IN)
                .status(OrderStatus.NEW)
                .build();
        order = orderRepository.save(order);

        tableService.assignTableOrder(primary.getTableId(), order.getOrderId());

        RestaurantTable fetchedPrimary = tableService.getTableById(primary.getTableId());
        RestaurantTable fetchedSec = tableService.getTableById(secondary.getTableId());

        assertEquals(TableStatus.OCCUPIED, fetchedPrimary.getStatus());
        assertEquals(order.getOrderId(), fetchedPrimary.getCurrentOrderId());

        assertEquals(TableStatus.OCCUPIED, fetchedSec.getStatus());
        assertEquals(order.getOrderId(), fetchedSec.getCurrentOrderId());

        tableService.releaseTable(primary.getTableId());

        fetchedPrimary = tableService.getTableById(primary.getTableId());
        fetchedSec = tableService.getTableById(secondary.getTableId());

        assertEquals(TableStatus.AVAILABLE, fetchedPrimary.getStatus());
        assertNull(fetchedPrimary.getCurrentOrderId());
        assertEquals(TableStatus.AVAILABLE, fetchedSec.getStatus());
        assertNull(fetchedSec.getCurrentOrderId());

        tableService.unmergeTables(primary.getTableId());
        fetchedSec = tableService.getTableById(secondary.getTableId());
        assertNull(fetchedSec.getParentTableId());
    }

    @Test
    public void testGuestTransfer() {
        RestaurantTable source = tableService.createTable(RestaurantTable.builder()
                .outletId(outletId)
                .tableNumber("Source")
                .capacity(4)
                .build());

        RestaurantTable dest = tableService.createTable(RestaurantTable.builder()
                .outletId(outletId)
                .tableNumber("Dest")
                .capacity(4)
                .build());

        Order order = Order.builder()
                .outletId(outletId)
                .tableId(source.getTableId())
                .orderType(OrderType.DINE_IN)
                .status(OrderStatus.NEW)
                .build();
        order = orderRepository.save(order);
        tableService.assignTableOrder(source.getTableId(), order.getOrderId());

        tableService.transferTable(source.getTableId(), dest.getTableId());

        RestaurantTable fetchedSource = tableService.getTableById(source.getTableId());
        RestaurantTable fetchedDest = tableService.getTableById(dest.getTableId());

        assertEquals(TableStatus.AVAILABLE, fetchedSource.getStatus());
        assertNull(fetchedSource.getCurrentOrderId());

        assertEquals(TableStatus.OCCUPIED, fetchedDest.getStatus());
        assertEquals(order.getOrderId(), fetchedDest.getCurrentOrderId());

        Order fetchedOrder = orderRepository.findById(order.getOrderId()).orElseThrow();
        assertEquals(dest.getTableId(), fetchedOrder.getTableId());
    }

    @Test
    public void testReservationHoldAndAutoRelease() {
        RestaurantTable table = tableService.createTable(RestaurantTable.builder()
                .outletId(outletId)
                .tableNumber("R1")
                .capacity(4)
                .build());

        Reservation activeRes = Reservation.builder()
                .outletId(outletId)
                .guestName("Alice")
                .guestPhone("1234567890")
                .partySize(4)
                .date(LocalDate.now())
                .time(LocalTime.now())
                .tableId(table.getTableId())
                .status(ReservationStatus.CONFIRMED)
                .build();
        reservationRepository.save(activeRes);

        reservationScheduler.checkAndReleaseReservations();

        RestaurantTable fetchedTable = tableService.getTableById(table.getTableId());
        assertEquals(TableStatus.RESERVED, fetchedTable.getStatus());

        reservationRepository.deleteAll();
        Reservation expiredRes = Reservation.builder()
                .outletId(outletId)
                .guestName("Bob")
                .guestPhone("9876543210")
                .partySize(4)
                .date(LocalDate.now())
                .time(LocalTime.now().minusMinutes(20))
                .tableId(table.getTableId())
                .status(ReservationStatus.CONFIRMED)
                .build();
        reservationRepository.save(expiredRes);

        table.setStatus(TableStatus.RESERVED);
        tableRepository.save(table);

        reservationScheduler.checkAndReleaseReservations();

        Reservation fetchedRes = reservationRepository.findById(expiredRes.getReservationId()).orElseThrow();
        assertEquals(ReservationStatus.NO_SHOW, fetchedRes.getStatus());

        fetchedTable = tableService.getTableById(table.getTableId());
        assertEquals(TableStatus.AVAILABLE, fetchedTable.getStatus());
    }

    @Test
    public void testWaitlistQueueMatchingAndNotification() {
        RestaurantTable table = tableService.createTable(RestaurantTable.builder()
                .outletId(outletId)
                .tableNumber("W1")
                .capacity(3)
                .status(TableStatus.OCCUPIED)
                .build());

        WaitlistEntry largeParty = waitlistService.addToWaitlist(WaitlistEntry.builder()
                .outletId(outletId)
                .guestName("Large")
                .guestPhone("111111")
                .partySize(5)
                .build());

        WaitlistEntry matchParty = waitlistService.addToWaitlist(WaitlistEntry.builder()
                .outletId(outletId)
                .guestName("Match")
                .guestPhone("222222")
                .partySize(2)
                .build());

        tableService.releaseTable(table.getTableId());

        WaitlistEntry fetchedLarge = waitlistRepository.findById(largeParty.getId()).orElseThrow();
        WaitlistEntry fetchedMatch = waitlistRepository.findById(matchParty.getId()).orElseThrow();

        assertEquals(WaitlistStatus.WAITING, fetchedLarge.getStatus());
        assertEquals(WaitlistStatus.NOTIFIED, fetchedMatch.getStatus());
        assertNotNull(fetchedMatch.getNotifiedAt());
    }
}
