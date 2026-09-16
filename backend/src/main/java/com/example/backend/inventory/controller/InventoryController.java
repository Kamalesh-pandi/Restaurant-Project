package com.example.backend.inventory.controller;

import com.example.backend.inventory.dto.*;
import com.example.backend.inventory.entity.*;
import com.example.backend.inventory.service.InventoryService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/inventory")
@PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
public class InventoryController {

    private final InventoryService inventoryService;

    public InventoryController(InventoryService inventoryService) {
        this.inventoryService = inventoryService;
    }

    @GetMapping
    public ResponseEntity<List<InventoryItem>> getAllInventory() {
        return ResponseEntity.ok(inventoryService.getAllInventory());
    }

    @PostMapping("/grn")
    public ResponseEntity<InventoryItem> recordGRN(@RequestParam UUID ingredientId,
                                                   @RequestParam BigDecimal quantityReceived,
                                                   @RequestParam(required = false) BigDecimal costPrice) {
        return ResponseEntity.ok(inventoryService.recordGRN(ingredientId, quantityReceived, costPrice));
    }

    @GetMapping("/alerts")
    public ResponseEntity<List<InventoryItem>> getLowStockAlerts() {
        return ResponseEntity.ok(inventoryService.getLowStockAlerts());
    }

    @PostMapping("/suppliers")
    public ResponseEntity<Supplier> createSupplier(@RequestBody SupplierRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(inventoryService.createSupplier(request));
    }

    @GetMapping("/suppliers")
    public ResponseEntity<List<Supplier>> getAllSuppliers() {
        return ResponseEntity.ok(inventoryService.getAllSuppliers());
    }

    @PostMapping("/daily-stock/opening")
    public ResponseEntity<List<DailyStockSheet>> setupDailyOpeningStock(@RequestBody List<DailyStockSetupRequest> requests) {
        return ResponseEntity.ok(inventoryService.setupDailyOpeningStock(requests));
    }

    @PostMapping("/daily-stock/closing")
    public ResponseEntity<List<DailyStockSheet>> registerClosingStock(@RequestBody List<DailyStockCloseRequest> requests) {
        return ResponseEntity.ok(inventoryService.registerClosingStock(requests));
    }

    @PostMapping("/purchase-orders")
    public ResponseEntity<PurchaseOrder> raisePurchaseOrder(@RequestBody PurchaseOrderRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(inventoryService.raisePurchaseOrder(request));
    }

    @PostMapping("/purchase-orders/{id}/receive")
    public ResponseEntity<PurchaseOrder> receivePurchaseOrderGRN(@PathVariable UUID id) {
        return ResponseEntity.ok(inventoryService.receivePurchaseOrderGRN(id));
    }

    @GetMapping("/reports/cogs")
    public ResponseEntity<List<CogsReportResponse>> getCogsReport() {
        return ResponseEntity.ok(inventoryService.getCogsReport());
    }

    @GetMapping("/batches")
    public ResponseEntity<List<PerishableBatch>> getAllPerishableBatches() {
        return ResponseEntity.ok(inventoryService.getAllPerishableBatches());
    }
}
