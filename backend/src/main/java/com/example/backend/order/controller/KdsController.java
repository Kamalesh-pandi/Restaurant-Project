package com.example.backend.order.controller;

import com.example.backend.order.dto.KdsItemResponse;
import com.example.backend.order.dto.KdsPerformanceResponse;
import com.example.backend.order.dto.KdsSyncRequest;
import com.example.backend.order.entity.OrderItem;
import com.example.backend.order.entity.OrderItemStatus;
import com.example.backend.order.entity.Order;
import com.example.backend.order.service.KdsService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/kds")
@PreAuthorize("hasAnyRole('KITCHEN', 'MANAGER', 'ADMIN')")
public class KdsController {

    private final KdsService kdsService;

    public KdsController(KdsService kdsService) {
        this.kdsService = kdsService;
    }

    @GetMapping
    public ResponseEntity<List<KdsItemResponse>> getAllKdsOrders() {
        return ResponseEntity.ok(kdsService.getAllKdsOrders());
    }

    @GetMapping("/{stationId}/orders")
    public ResponseEntity<List<KdsItemResponse>> getKdsOrdersByStation(@PathVariable UUID stationId) {
        return ResponseEntity.ok(kdsService.getKdsOrdersByStation(stationId));
    }

    @PutMapping("/items/{itemId}/bump")
    public ResponseEntity<OrderItem> bumpItem(@PathVariable UUID itemId) {
        return ResponseEntity.ok(kdsService.bumpItem(itemId));
    }

    @GetMapping("/{stationId}/recalled")
    public ResponseEntity<List<KdsItemResponse>> getRecalledBumps(@PathVariable UUID stationId) {
        return ResponseEntity.ok(kdsService.getRecalledBumps(stationId));
    }

    @GetMapping("/performance")
    public ResponseEntity<KdsPerformanceResponse> getPerformanceMetrics(@RequestParam UUID stationId) {
        return ResponseEntity.ok(kdsService.getPerformanceMetrics(stationId));
    }

    @PutMapping("/orders/{orderId}/items/{itemId}/status")
    public ResponseEntity<OrderItem> updateItemStatus(@PathVariable UUID orderId,
                                                      @PathVariable UUID itemId,
                                                      @RequestParam String status) {
        OrderItemStatus itemStatus = OrderItemStatus.valueOf(status.toUpperCase());
        return ResponseEntity.ok(kdsService.updateItemStatus(itemId, itemStatus));
    }

    @PutMapping("/orders/{orderId}/ready")
    public ResponseEntity<Order> markOrderReady(@PathVariable UUID orderId) {
        return ResponseEntity.ok(kdsService.markOrderReady(orderId));
    }

    @PutMapping("/orders/{orderId}/served")
    public ResponseEntity<Order> markOrderServed(@PathVariable UUID orderId) {
        return ResponseEntity.ok(kdsService.markOrderServed(orderId));
    }

    @PostMapping("/sync")
    public ResponseEntity<List<OrderItem>> syncOfflineBumps(@RequestBody KdsSyncRequest syncRequest) {
        return ResponseEntity.ok(kdsService.syncOfflineBumps(syncRequest.getBumpedItemIds()));
    }
}
