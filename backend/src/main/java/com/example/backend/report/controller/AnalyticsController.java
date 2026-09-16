package com.example.backend.report.controller;

import com.example.backend.report.dto.*;
import com.example.backend.report.entity.DayEndReport;
import com.example.backend.report.service.AnalyticsService;
import com.example.backend.staff.dto.StaffPerformanceResponse;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/analytics")
public class AnalyticsController {

    private final AnalyticsService analyticsService;

    public AnalyticsController(AnalyticsService analyticsService) {
        this.analyticsService = analyticsService;
    }

    @GetMapping("/daily-sales")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<DailySalesSummaryResponse> getDailySalesSummary(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            @RequestParam(required = false) UUID outletId) {
        return ResponseEntity.ok(analyticsService.getDailySalesSummary(startDate, endDate, outletId));
    }

    @GetMapping("/x-report")
    @PreAuthorize("hasAnyRole('CASHIER', 'MANAGER', 'ADMIN')")
    public ResponseEntity<XReportResponse> getXReport(@RequestParam(required = false) UUID outletId) {
        return ResponseEntity.ok(analyticsService.getXReport(outletId));
    }

    @PostMapping("/z-report")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<DayEndReport> generateZReport(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestParam(required = false) UUID outletId,
            @RequestParam(required = false) UUID managerId) {
        return ResponseEntity.ok(analyticsService.generateZReport(date, outletId, managerId));
    }

    @GetMapping("/item-performance")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<ItemPerformanceResponse> getItemPerformance(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            @RequestParam(required = false) UUID outletId,
            @RequestParam(required = false) String category) {
        return ResponseEntity.ok(analyticsService.getItemPerformance(startDate, endDate, outletId, category));
    }

    @GetMapping("/food-cost")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<Map<String, Object>> getFoodCostReport(@RequestParam(required = false) UUID outletId) {
        return ResponseEntity.ok(analyticsService.getFoodCostReport(outletId));
    }

    @GetMapping("/table-analytics")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<TableAnalyticsResponse> getTableAnalytics(@RequestParam(required = false) UUID outletId) {
        return ResponseEntity.ok(analyticsService.getTableAnalytics(outletId));
    }

    @GetMapping("/delivery-report")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<DeliveryAnalyticsResponse> getDeliveryReport(@RequestParam(required = false) UUID outletId) {
        return ResponseEntity.ok(analyticsService.getDeliveryReport(outletId));
    }

    @GetMapping("/customer-analytics")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<CustomerAnalyticsReportResponse> getCustomerAnalyticsReport() {
        return ResponseEntity.ok(analyticsService.getCustomerAnalyticsReport());
    }

    @GetMapping("/staff-productivity")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<List<StaffPerformanceResponse>> getStaffProductivityReport(@RequestParam(required = false) UUID outletId) {
        return ResponseEntity.ok(analyticsService.getStaffProductivityReport(outletId));
    }
}
