package com.example.backend.table.controller;

import com.example.backend.table.entity.WaitlistEntry;
import com.example.backend.table.service.WaitlistService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/waitlist")
public class WaitlistController {

    private final WaitlistService waitlistService;

    public WaitlistController(WaitlistService waitlistService) {
        this.waitlistService = waitlistService;
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('CASHIER', 'CAPTAIN', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<WaitlistEntry>> getWaitlist(@RequestParam(required = false) UUID outletId) {
        return ResponseEntity.ok(waitlistService.getWaitingList(outletId));
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('CASHIER', 'CAPTAIN', 'MANAGER', 'ADMIN')")
    public ResponseEntity<WaitlistEntry> addToWaitlist(@Valid @RequestBody WaitlistEntry entry) {
        return ResponseEntity.status(HttpStatus.CREATED).body(waitlistService.addToWaitlist(entry));
    }

    @PutMapping("/{id}/seat")
    @PreAuthorize("hasAnyRole('CASHIER', 'CAPTAIN', 'MANAGER', 'ADMIN')")
    public ResponseEntity<WaitlistEntry> seatGuest(@PathVariable UUID id, @RequestParam UUID tableId) {
        return ResponseEntity.ok(waitlistService.seatWaitlistEntry(id, tableId));
    }

    @PutMapping("/{id}/cancel")
    @PreAuthorize("hasAnyRole('CASHIER', 'CAPTAIN', 'MANAGER', 'ADMIN')")
    public ResponseEntity<WaitlistEntry> cancelEntry(@PathVariable UUID id) {
        return ResponseEntity.ok(waitlistService.cancelWaitlistEntry(id));
    }
}
