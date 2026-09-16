package com.example.backend.delivery.controller;

import com.example.backend.delivery.dto.*;
import com.example.backend.delivery.entity.DeliveryPartnerStatus;
import com.example.backend.delivery.service.DeliveryService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/delivery-partner")
public class DeliveryPartnerController {

    private final DeliveryService deliveryService;

    public DeliveryPartnerController(DeliveryService deliveryService) {
        this.deliveryService = deliveryService;
    }

    @PostMapping("/login-pin")
    public ResponseEntity<DeliveryPinLoginResponse> loginWithPin(@RequestBody DeliveryPinLoginRequest request) {
        return ResponseEntity.ok(deliveryService.loginWithPin(request));
    }

    @PostMapping("/register")
    public ResponseEntity<DeliveryPinLoginResponse> registerPartner(@RequestBody DeliveryPartnerRequest request) {
        return ResponseEntity.ok(deliveryService.registerPartner(request));
    }

    @PutMapping("/{partnerId}/status")
    public ResponseEntity<DeliveryPartnerResponse> updateStatus(@PathVariable UUID partnerId,
                                                                 @RequestParam DeliveryPartnerStatus status) {
        return ResponseEntity.ok(deliveryService.updatePartnerStatus(partnerId, status));
    }

    @PutMapping("/{partnerId}/location")
    public ResponseEntity<DeliveryPartnerResponse> updateLocation(@PathVariable UUID partnerId,
                                                                   @RequestBody LocationUpdateRequest request) {
        return ResponseEntity.ok(deliveryService.updateLocation(partnerId, request.getLatitude(), request.getLongitude()));
    }

    @GetMapping("/{partnerId}/my-deliveries")
    public ResponseEntity<List<DeliveryAssignmentResponse>> getMyDeliveries(@PathVariable UUID partnerId) {
        return ResponseEntity.ok(deliveryService.getPartnerDeliveries(partnerId));
    }

    @PostMapping("/deliveries/{assignmentId}/accept")
    public ResponseEntity<DeliveryAssignmentResponse> acceptAssignment(@PathVariable UUID assignmentId,
                                                                        @RequestParam UUID partnerId) {
        return ResponseEntity.ok(deliveryService.acceptAssignment(assignmentId, partnerId));
    }

    @PostMapping("/deliveries/{assignmentId}/reject")
    public ResponseEntity<DeliveryAssignmentResponse> rejectAssignment(@PathVariable UUID assignmentId,
                                                                        @RequestParam UUID partnerId) {
        return ResponseEntity.ok(deliveryService.rejectAssignment(assignmentId, partnerId));
    }

    @PostMapping("/deliveries/{assignmentId}/pickup")
    public ResponseEntity<DeliveryAssignmentResponse> pickupOrder(@PathVariable UUID assignmentId,
                                                                   @RequestParam UUID partnerId) {
        return ResponseEntity.ok(deliveryService.pickupOrder(assignmentId, partnerId));
    }

    @PostMapping("/deliveries/{assignmentId}/deliver")
    public ResponseEntity<DeliveryAssignmentResponse> completeDelivery(@PathVariable UUID assignmentId,
                                                                        @RequestParam UUID partnerId,
                                                                        @RequestBody CompleteDeliveryRequest request) {
        return ResponseEntity.ok(deliveryService.completeDelivery(assignmentId, partnerId, request));
    }

    @GetMapping("/{partnerId}")
    public ResponseEntity<DeliveryPartnerResponse> getPartner(@PathVariable UUID partnerId) {
        return ResponseEntity.ok(deliveryService.getPartnerById(partnerId));
    }

    @GetMapping("/{partnerId}/stats")
    public ResponseEntity<DeliveryPartnerStatsResponse> getPartnerStats(@PathVariable UUID partnerId) {
        return ResponseEntity.ok(deliveryService.getPartnerStats(partnerId));
    }

    @GetMapping("/{partnerId}/active-assignment")
    public ResponseEntity<DeliveryAssignmentResponse> getActiveAssignment(@PathVariable UUID partnerId) {
        DeliveryAssignmentResponse active = deliveryService.getActiveAssignment(partnerId);
        if (active == null) {
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.ok(active);
    }
}
