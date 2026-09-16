package com.example.backend.delivery.controller;

import com.example.backend.delivery.dto.*;
import com.example.backend.delivery.service.DeliveryService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/delivery-management")
public class DeliveryManagementController {

    private final DeliveryService deliveryService;

    public DeliveryManagementController(DeliveryService deliveryService) {
        this.deliveryService = deliveryService;
    }

    @PostMapping("/register-partner")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<DeliveryPartnerResponse> registerPartner(@RequestBody DeliveryPartnerRequest request) {
        return ResponseEntity.ok(deliveryService.registerPartner(request).getPartner());
    }

    @PostMapping("/orders/{orderId}/assign")
    @PreAuthorize("hasAnyRole('CASHIER', 'MANAGER', 'CAPTAIN', 'ADMIN', 'KITCHEN')")
    public ResponseEntity<DeliveryAssignmentResponse> assignOrder(@PathVariable UUID orderId,
                                                                   @RequestParam UUID partnerId) {
        return ResponseEntity.ok(deliveryService.assignOrderToPartner(orderId, partnerId));
    }

    @PostMapping("/orders/{orderId}/auto-assign")
    @PreAuthorize("hasAnyRole('CASHIER', 'MANAGER', 'CAPTAIN', 'ADMIN', 'KITCHEN')")
    public ResponseEntity<DeliveryAssignmentResponse> autoAssignOrder(@PathVariable UUID orderId) {
        return ResponseEntity.ok(deliveryService.autoAssignOrder(orderId));
    }

    @GetMapping("/active-partners")
    @PreAuthorize("hasAnyRole('CASHIER', 'MANAGER', 'CAPTAIN', 'ADMIN', 'KITCHEN')")
    public ResponseEntity<List<DeliveryPartnerResponse>> getActivePartners(@RequestParam(required = false) UUID outletId) {
        return ResponseEntity.ok(deliveryService.getActivePartners(outletId));
    }

    @GetMapping("/active-deliveries")
    @PreAuthorize("hasAnyRole('CASHIER', 'MANAGER', 'CAPTAIN', 'ADMIN', 'KITCHEN')")
    public ResponseEntity<List<DeliveryAssignmentResponse>> getActiveDeliveries() {
        return ResponseEntity.ok(deliveryService.getActiveDeliveries());
    }
}
