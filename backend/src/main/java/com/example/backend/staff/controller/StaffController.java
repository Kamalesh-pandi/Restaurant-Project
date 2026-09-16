package com.example.backend.staff.controller;

import com.example.backend.staff.dto.*;
import com.example.backend.staff.entity.*;
import com.example.backend.staff.service.StaffService;
import jakarta.validation.Valid;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/staff")
public class StaffController {

    private final StaffService staffService;

    public StaffController(StaffService staffService) {
        this.staffService = staffService;
    }

    @GetMapping
    public ResponseEntity<List<StaffResponse>> getAllStaff() {
        return ResponseEntity.ok(staffService.getAllStaff());
    }

    @GetMapping("/{id}")
    public ResponseEntity<StaffResponse> getStaffById(@PathVariable UUID id) {
        return ResponseEntity.ok(staffService.getStaffById(id));
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<StaffResponse> createStaff(@Valid @RequestBody StaffRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(staffService.createStaff(request));
    }

    @PostMapping("/login-pin")
    public ResponseEntity<PinLoginResponse> loginWithPin(@RequestBody PinLoginRequest request) {
        return ResponseEntity.ok(staffService.loginWithPin(request));
    }

    @PostMapping("/clock-in")
    public ResponseEntity<AttendanceLog> clockIn(@RequestParam String name, @RequestParam String pin) {
        return ResponseEntity.ok(staffService.clockIn(name, pin));
    }

    @PostMapping("/clock-out")
    public ResponseEntity<AttendanceLog> clockOut(@RequestParam String name, @RequestParam String pin) {
        return ResponseEntity.ok(staffService.clockOut(name, pin));
    }

    @PostMapping("/shifts")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<Shift> createShift(@RequestBody Shift shift) {
        return ResponseEntity.status(HttpStatus.CREATED).body(staffService.createShift(shift));
    }

    @PostMapping("/shifts/assign")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<ShiftAssignment> assignStaffToShift(@RequestBody ShiftAssignmentRequest request) {
        return ResponseEntity.ok(staffService.assignStaffToShift(request));
    }

    @PostMapping("/audit")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<AuditLog> logManagerAudit(@RequestParam String action,
                                                    @RequestParam(required = false) UUID orderId,
                                                    @RequestParam(required = false) BigDecimal amount,
                                                    @RequestParam(required = false) String reason,
                                                    @RequestParam String managerPin) {
        return ResponseEntity.ok(staffService.logManagerAudit(action, orderId, amount, reason, managerPin));
    }

    @GetMapping("/{id}/performance")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<StaffPerformanceResponse> getStaffPerformance(@PathVariable UUID id) {
        return ResponseEntity.ok(staffService.getStaffPerformance(id));
    }

    @GetMapping("/payroll/export")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<String> exportPayrollCsv() {
        String csv = staffService.exportPayrollCsv();
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=payroll_export.csv")
                .contentType(MediaType.parseMediaType("text/csv"))
                .body(csv);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<StaffResponse> updateStaff(@PathVariable UUID id, @Valid @RequestBody StaffRequest request) {
        return ResponseEntity.ok(staffService.updateStaff(id, request));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<Void> deleteStaff(@PathVariable UUID id) {
        staffService.deleteStaff(id);
        return ResponseEntity.noContent().build();
    }

    @PatchMapping("/{id}/toggle-active")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<StaffResponse> toggleStaffActive(@PathVariable UUID id) {
        return ResponseEntity.ok(staffService.toggleStaffActive(id));
    }
}
