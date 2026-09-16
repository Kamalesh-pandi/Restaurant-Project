package com.example.backend.staff.service;

import com.example.backend.common.service.EmailService;
import com.example.backend.order.repository.OrderRepository;
import com.example.backend.security.JwtUtil;
import com.example.backend.staff.dto.*;
import com.example.backend.staff.entity.*;
import com.example.backend.staff.repository.*;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class StaffService {

    private final StaffRepository staffRepository;
    private final ShiftRepository shiftRepository;
    private final ShiftAssignmentRepository shiftAssignmentRepository;
    private final AttendanceLogRepository attendanceLogRepository;
    private final AuditLogRepository auditLogRepository;
    private final OrderRepository orderRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final EmailService emailService;

    public StaffService(StaffRepository staffRepository,
                        ShiftRepository shiftRepository,
                        ShiftAssignmentRepository shiftAssignmentRepository,
                        AttendanceLogRepository attendanceLogRepository,
                        AuditLogRepository auditLogRepository,
                        OrderRepository orderRepository,
                        PasswordEncoder passwordEncoder,
                        JwtUtil jwtUtil,
                        EmailService emailService) {
        this.staffRepository = staffRepository;
        this.shiftRepository = shiftRepository;
        this.shiftAssignmentRepository = shiftAssignmentRepository;
        this.attendanceLogRepository = attendanceLogRepository;
        this.auditLogRepository = auditLogRepository;
        this.orderRepository = orderRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtUtil = jwtUtil;
        this.emailService = emailService;
    }

    public List<StaffResponse> getAllStaff() {
        return staffRepository.findAll().stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    public StaffResponse getStaffById(UUID id) {
        Staff staff = staffRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Staff member not found with ID: " + id));
        return mapToResponse(staff);
    }

    public StaffResponse createStaff(StaffRequest request) {
        if (request.getEmail() != null && staffRepository.findByEmail(request.getEmail()).isPresent()) {
            throw new RuntimeException("Email already registered: " + request.getEmail());
        }

        String pin = (request.getPin() != null && !request.getPin().isBlank())
                ? request.getPin()
                : generateRandomPin();

        String phone = (request.getPhoneNumber() != null && !request.getPhoneNumber().trim().isEmpty())
                ? request.getPhoneNumber().trim()
                : "9999999999";

        Staff staff = Staff.builder()
                .name(request.getName())
                .email(request.getEmail())
                .phoneNumber(phone)
                .role(request.getRole())
                .section(request.getSection() != null ? request.getSection() : "General")
                .pinHash(passwordEncoder.encode(pin))
                .outletId(request.getOutletId())
                .isActive(true)
                .build();

        Staff saved = staffRepository.save(staff);

        try {
            emailService.sendStaffPinEmail(saved.getEmail(), saved.getName(), pin, saved.getRole() != null ? saved.getRole().name() : "STAFF");
        } catch (Exception e) {
            System.err.println("[EMAIL WARNING] Could not send PIN email: " + e.getMessage());
        }

        return mapToResponse(saved);
    }

    public StaffResponse updateStaff(UUID id, StaffRequest request) {
        Staff staff = staffRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Staff member not found with ID: " + id));

        staff.setName(request.getName());
        staff.setEmail(request.getEmail());
        if (request.getPhoneNumber() != null && !request.getPhoneNumber().trim().isEmpty()) {
            staff.setPhoneNumber(request.getPhoneNumber().trim());
        }
        staff.setRole(request.getRole());
        if (request.getSection() != null) staff.setSection(request.getSection());
        if (request.getOutletId() != null) staff.setOutletId(request.getOutletId());

        if (request.getPin() != null && !request.getPin().isBlank()) {
            staff.setPinHash(passwordEncoder.encode(request.getPin()));
            try {
                emailService.sendStaffPinEmail(staff.getEmail(), staff.getName(), request.getPin(), staff.getRole() != null ? staff.getRole().name() : "STAFF");
            } catch (Exception e) {
                System.err.println("[EMAIL WARNING] Could not send updated PIN email: " + e.getMessage());
            }
        }

        return mapToResponse(staffRepository.save(staff));
    }

    public void deleteStaff(UUID id) {
        Staff staff = staffRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Staff member not found with ID: " + id));
        staffRepository.delete(staff);
    }

    public StaffResponse toggleStaffActive(UUID id) {
        Staff staff = staffRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Staff member not found with ID: " + id));
        staff.setActive(!staff.isActive());
        return mapToResponse(staffRepository.save(staff));
    }

    public PinLoginResponse loginWithPin(PinLoginRequest request) {
        String pin = request.getPin();
        String name = request.getName();

        Staff staff = null;

        if (name != null && !name.trim().isEmpty()) {
            staff = staffRepository.findAll().stream()
                    .filter(s -> (s.getName() != null && s.getName().equalsIgnoreCase(name)) || (s.getEmail() != null && s.getEmail().equalsIgnoreCase(name)))
                    .findFirst()
                    .orElse(null);
        }

        if (staff == null) {
            staff = staffRepository.findAll().stream()
                    .filter(s -> (s.getPinHash() != null && passwordEncoder.matches(pin, s.getPinHash())))
                    .findFirst()
                    .orElse(null);
        }

        // Standard PIN Fallback for default staff roles
        if (staff == null) {
            if ("1111".equals(pin) || "1234".equals(pin)) {
                staff = staffRepository.findAll().stream().filter(s -> s.getRole() == StaffRole.MANAGER).findFirst().orElse(null);
            } else if ("2222".equals(pin)) {
                staff = staffRepository.findAll().stream().filter(s -> s.getRole() == StaffRole.CASHIER).findFirst().orElse(null);
            } else if ("3333".equals(pin)) {
                staff = staffRepository.findAll().stream().filter(s -> s.getRole() == StaffRole.CAPTAIN).findFirst().orElse(null);
            } else if ("4444".equals(pin)) {
                staff = staffRepository.findAll().stream().filter(s -> s.getRole() == StaffRole.KITCHEN).findFirst().orElse(null);
            }
        }

        if (staff == null) {
            throw new RuntimeException("Invalid Staff PIN Code. Valid PINs: 1111 (Manager), 2222 (Cashier), 3333 (Captain), 4444 (Kitchen)");
        }

        if (!staff.isActive()) {
            throw new RuntimeException("Staff member account is currently inactive. Contact Manager.");
        }

        String token = jwtUtil.generateToken(staff.getName());

        return PinLoginResponse.builder()
                .token(token)
                .staffId(staff.getStaffId())
                .name(staff.getName())
                .role(staff.getRole())
                .autoExpireMinutes(30)
                .build();
    }

    // Attendance Log: Clock-In
    public AttendanceLog clockIn(String name, String pin) {
        Staff staff = staffRepository.findAll().stream()
                .filter(s -> s.getName().equalsIgnoreCase(name) || (s.getEmail() != null && s.getEmail().equalsIgnoreCase(name)))
                .findFirst()
                .orElseThrow(() -> new RuntimeException("Invalid staff member name"));

        if (staff.getPinHash() == null || !passwordEncoder.matches(pin, staff.getPinHash())) {
            throw new RuntimeException("Invalid staff PIN");
        }

        AttendanceLog log = AttendanceLog.builder()
                .staffId(staff.getStaffId())
                .clockIn(LocalDateTime.now())
                .build();

        return attendanceLogRepository.save(log);
    }

    // Attendance Log: Clock-Out
    public AttendanceLog clockOut(String name, String pin) {
        Staff staff = staffRepository.findAll().stream()
                .filter(s -> s.getName().equalsIgnoreCase(name) || (s.getEmail() != null && s.getEmail().equalsIgnoreCase(name)))
                .findFirst()
                .orElseThrow(() -> new RuntimeException("Invalid staff member name"));

        if (staff.getPinHash() == null || !passwordEncoder.matches(pin, staff.getPinHash())) {
            throw new RuntimeException("Invalid staff PIN");
        }

        AttendanceLog log = attendanceLogRepository.findFirstByStaffIdAndClockOutIsNullOrderByClockInDesc(staff.getStaffId())
                .orElseThrow(() -> new RuntimeException("No active clock-in session found for " + name));

        log.setClockOut(LocalDateTime.now());
        long minutes = Duration.between(log.getClockIn(), log.getClockOut()).toMinutes();
        log.setHoursWorked(BigDecimal.valueOf(minutes / 60.0));

        return attendanceLogRepository.save(log);
    }

    // Shift Management
    public Shift createShift(Shift shift) {
        return shiftRepository.save(shift);
    }

    public ShiftAssignment assignStaffToShift(ShiftAssignmentRequest request) {
        Staff staff = staffRepository.findById(request.getStaffId())
                .orElseThrow(() -> new RuntimeException("Staff member not found"));

        Shift shift = shiftRepository.findById(request.getShiftId())
                .orElseThrow(() -> new RuntimeException("Shift not found"));

        // Check for shift overlap on the same date
        List<ShiftAssignment> existingAssignments = shiftAssignmentRepository.findByStaffIdAndAssignmentDate(staff.getStaffId(), request.getAssignmentDate());
        for (ShiftAssignment existing : existingAssignments) {
            Shift existingShift = shiftRepository.findById(existing.getShiftId()).orElse(null);
            if (existingShift != null) {
                // Overlap condition: start < existing.end and end > existing.start
                if (shift.getStartTime().isBefore(existingShift.getEndTime()) && shift.getEndTime().isAfter(existingShift.getStartTime())) {
                    throw new RuntimeException("Shift overlap detected with shift: " + existingShift.getName());
                }
            }
        }

        ShiftAssignment assignment = ShiftAssignment.builder()
                .staffId(staff.getStaffId())
                .shiftId(shift.getId())
                .assignmentDate(request.getAssignmentDate())
                .build();

        return shiftAssignmentRepository.save(assignment);
    }

    // Manager Audit Override Logging
    public AuditLog logManagerAudit(String action, UUID orderId, BigDecimal amount, String reason, String managerPin) {
        Staff manager = staffRepository.findAll().stream()
                .filter(s -> (s.getRole() == StaffRole.MANAGER) && s.getPinHash() != null && passwordEncoder.matches(managerPin, s.getPinHash()))
                .findFirst()
                .orElseThrow(() -> new RuntimeException("Invalid Manager PIN for audit override authorization"));

        AuditLog audit = AuditLog.builder()
                .managerId(manager.getStaffId())
                .managerName(manager.getName())
                .action(action)
                .orderId(orderId)
                .amount(amount)
                .reason(reason)
                .timestamp(LocalDateTime.now())
                .build();

        return auditLogRepository.save(audit);
    }

    // Staff Performance Metrics
    public StaffPerformanceResponse getStaffPerformance(UUID staffId) {
        Staff staff = staffRepository.findById(staffId)
                .orElseThrow(() -> new RuntimeException("Staff member not found"));

        List<AttendanceLog> logs = attendanceLogRepository.findByStaffId(staff.getStaffId());

        double totalHours = logs.stream()
                .filter(l -> l.getHoursWorked() != null)
                .mapToDouble(l -> l.getHoursWorked().doubleValue())
                .sum();

        long ordersProcessed = 0;
        BigDecimal totalSalesGenerated = BigDecimal.ZERO;

        if (orderRepository != null) {
            ordersProcessed = orderRepository.count();
        }

        return StaffPerformanceResponse.builder()
                .staffId(staff.getStaffId())
                .name(staff.getName())
                .role(staff.getRole())
                .totalOrders(ordersProcessed)
                .totalSales(totalSalesGenerated)
                .build();
    }

    // Export Payroll CSV Report
    public String exportPayrollCsv() {
        List<Staff> allStaff = staffRepository.findAll();
        StringBuilder csv = new StringBuilder();
        csv.append("Staff ID,Name,Role,Email,Phone,Employment Type,Status,Total Hours Worked,Estimated Payroll\n");

        for (Staff s : allStaff) {
            List<AttendanceLog> logs = attendanceLogRepository.findByStaffId(s.getStaffId());
            double totalHours = logs.stream()
                    .filter(l -> l.getHoursWorked() != null)
                    .mapToDouble(l -> l.getHoursWorked().doubleValue())
                    .sum();

            double hourlyRate = 150.0; // Standard base rate per hour
            if (s.getRole() == StaffRole.MANAGER) hourlyRate = 300.0;
            if (s.getRole() == StaffRole.KITCHEN) hourlyRate = 200.0;

            double estimatedPay = totalHours * hourlyRate;

            csv.append(String.format("%s,\"%s\",%s,\"%s\",\"%s\",%s,%s,%.2f,%.2f\n",
                    s.getStaffId(),
                    s.getName(),
                    s.getRole(),
                    s.getEmail() != null ? s.getEmail() : "",
                    s.getPhoneNumber() != null ? s.getPhoneNumber() : "",
                    s.getEmploymentType() != null ? s.getEmploymentType() : "FULL_TIME",
                    s.isActive() ? "ACTIVE" : "INACTIVE",
                    totalHours,
                    estimatedPay
            ));
        }

        return csv.toString();
    }

    private StaffResponse mapToResponse(Staff staff) {
        return StaffResponse.builder()
                .staffId(staff.getStaffId())
                .outletId(staff.getOutletId())
                .name(staff.getName())
                .email(staff.getEmail())
                .phoneNumber(staff.getPhoneNumber())
                .role(staff.getRole())
                .section(staff.getSection())
                .employmentType(staff.getEmploymentType() != null ? staff.getEmploymentType() : "FULL_TIME")
                .isActive(staff.isActive())
                .build();
    }

    private String generateRandomPin() {
        int pin = 1000 + (int) (Math.random() * 9000);
        return String.valueOf(pin);
    }
}
