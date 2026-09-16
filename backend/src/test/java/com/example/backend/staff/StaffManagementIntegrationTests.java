package com.example.backend.staff;

import com.example.backend.order.entity.Order;
import com.example.backend.order.entity.OrderType;
import com.example.backend.order.repository.OrderRepository;
import com.example.backend.staff.dto.*;
import com.example.backend.staff.entity.*;
import com.example.backend.staff.repository.*;
import com.example.backend.staff.service.StaffService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@Transactional
public class StaffManagementIntegrationTests {

    @Autowired
    private StaffService staffService;

    @Autowired
    private StaffRepository staffRepository;

    @Autowired
    private AttendanceLogRepository attendanceLogRepository;

    @Autowired
    private ShiftRepository shiftRepository;

    @Autowired
    private ShiftAssignmentRepository shiftAssignmentRepository;

    @Autowired
    private AuditLogRepository auditLogRepository;

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    private UUID outletId;
    private Staff cashier;
    private Staff manager;

    @BeforeEach
    public void setUp() {
        outletId = UUID.randomUUID();
        auditLogRepository.deleteAll();
        shiftAssignmentRepository.deleteAll();
        shiftRepository.deleteAll();
        attendanceLogRepository.deleteAll();
        staffRepository.deleteAll();

        // Seed Cashier
        cashier = Staff.builder()
                .outletId(outletId)
                .name("Alice Cashier")
                .pinHash(passwordEncoder.encode("1111"))
                .role(StaffRole.CASHIER)
                .section("Front Desk")
                .employmentType("FULL_TIME")
                .isActive(true)
                .build();
        cashier = staffRepository.save(cashier);

        // Seed Manager
        manager = Staff.builder()
                .outletId(outletId)
                .name("Bob Manager")
                .pinHash(passwordEncoder.encode("9999"))
                .role(StaffRole.MANAGER)
                .section("All")
                .employmentType("FULL_TIME")
                .isActive(true)
                .build();
        manager = staffRepository.save(manager);
    }

    @Test
    public void testPinBasedLoginAndSessionAutoExpire() {
        PinLoginRequest loginReq = PinLoginRequest.builder()
                .name("Alice Cashier")
                .pin("1111")
                .build();

        PinLoginResponse response = staffService.loginWithPin(loginReq);
        assertNotNull(response.getToken());
        assertEquals("Alice Cashier", response.getName());
        assertEquals(StaffRole.CASHIER, response.getRole());
        assertEquals(30, response.getAutoExpireMinutes());
    }

    @Test
    public void testClockInClockOutAttendance() {
        AttendanceLog clockInLog = staffService.clockIn("Alice Cashier", "1111");
        assertNotNull(clockInLog.getClockIn());
        assertNull(clockInLog.getClockOut());

        AttendanceLog clockOutLog = staffService.clockOut("Alice Cashier", "1111");
        assertNotNull(clockOutLog.getClockOut());
        assertNotNull(clockOutLog.getHoursWorked());
    }

    @Test
    public void testShiftManagementAndOverlapDetection() {
        Shift morning = Shift.builder()
                .outletId(outletId)
                .name("Morning Shift")
                .startTime(LocalTime.of(8, 0))
                .endTime(LocalTime.of(16, 0))
                .build();
        morning = staffService.createShift(morning);

        Shift overlappingShift = Shift.builder()
                .outletId(outletId)
                .name("Midday Shift")
                .startTime(LocalTime.of(12, 0))
                .endTime(LocalTime.of(20, 0))
                .build();
        overlappingShift = staffService.createShift(overlappingShift);

        // Assign morning shift
        ShiftAssignmentRequest assign1 = ShiftAssignmentRequest.builder()
                .shiftId(morning.getId())
                .staffId(cashier.getStaffId())
                .assignmentDate(LocalDate.now())
                .build();
        assertDoesNotThrow(() -> staffService.assignStaffToShift(assign1));

        // Attempt overlapping shift assignment -> should throw exception
        ShiftAssignmentRequest assign2 = ShiftAssignmentRequest.builder()
                .shiftId(overlappingShift.getId())
                .staffId(cashier.getStaffId())
                .assignmentDate(LocalDate.now())
                .build();

        RuntimeException ex = assertThrows(RuntimeException.class, () -> staffService.assignStaffToShift(assign2));
        assertTrue(ex.getMessage().contains("Shift overlap detected"));
    }

    @Test
    public void testManagerAuditLog() {
        AuditLog log = staffService.logManagerAudit("DISCOUNT", UUID.randomUUID(), BigDecimal.valueOf(50.00), "Manager Special Discount", "9999");
        assertNotNull(log.getId());
        assertEquals("DISCOUNT", log.getAction());
        assertEquals("Bob Manager", log.getManagerName());
    }

    @Test
    public void testTrainingModeOrderFlagging() {
        Order trainingOrder = Order.builder()
                .outletId(outletId)
                .orderType(OrderType.DINE_IN)
                .captainId(cashier.getStaffId())
                .isTraining(true)
                .build();
        trainingOrder = orderRepository.save(trainingOrder);

        assertTrue(trainingOrder.getIsTraining());
    }

    @Test
    public void testStaffPerformanceAndPayrollCsvExport() {
        // Clock in & out
        staffService.clockIn("Alice Cashier", "1111");
        staffService.clockOut("Alice Cashier", "1111");

        StaffPerformanceResponse perf = staffService.getStaffPerformance(cashier.getStaffId());
        assertNotNull(perf);
        assertEquals("Alice Cashier", perf.getName());

        String csv = staffService.exportPayrollCsv();
        assertTrue(csv.contains("Alice Cashier"));
        assertTrue(csv.contains("FULL_TIME"));
    }
}
