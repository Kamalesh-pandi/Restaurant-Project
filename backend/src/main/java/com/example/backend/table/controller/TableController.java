package com.example.backend.table.controller;

import com.example.backend.order.entity.Order;
import com.example.backend.order.repository.OrderRepository;
import com.example.backend.table.entity.RestaurantTable;
import com.example.backend.table.entity.TableStatus;
import com.example.backend.table.service.TableService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/tables")
public class TableController {

    private final TableService tableService;
    private final OrderRepository orderRepository;

    public TableController(TableService tableService, OrderRepository orderRepository) {
        this.tableService = tableService;
        this.orderRepository = orderRepository;
    }

    @GetMapping("/{outletId}")
    @PreAuthorize("hasAnyRole('CASHIER', 'CAPTAIN', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<RestaurantTable>> getTablesByOutlet(@PathVariable UUID outletId, Principal principal) {
        String name = principal != null ? principal.getName() : null;
        return ResponseEntity.ok(tableService.getTablesForStaff(name, outletId));
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('CASHIER', 'CAPTAIN', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<RestaurantTable>> getAllTables(Principal principal) {
        String name = principal != null ? principal.getName() : null;
        return ResponseEntity.ok(tableService.getTablesForStaff(name, null));
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('CAPTAIN', 'MANAGER', 'ADMIN')")
    public ResponseEntity<RestaurantTable> createTable(@Valid @RequestBody RestaurantTable table) {
        return ResponseEntity.status(HttpStatus.CREATED).body(tableService.createTable(table));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<RestaurantTable> updateTable(@PathVariable UUID id, @Valid @RequestBody RestaurantTable table) {
        return ResponseEntity.ok(tableService.updateTable(id, table));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<Void> deleteTable(@PathVariable UUID id) {
        tableService.deleteTable(id);
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/bulk")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<List<RestaurantTable>> bulkUpdateTables(@Valid @RequestBody List<RestaurantTable> tables) {
        return ResponseEntity.ok(tableService.bulkUpdateTables(tables));
    }

    @PutMapping("/{id}/assign")
    @PreAuthorize("hasAnyRole('CAPTAIN', 'MANAGER', 'ADMIN')")
    public ResponseEntity<RestaurantTable> assignTable(@PathVariable UUID id, @RequestParam UUID orderId) {
        return ResponseEntity.ok(tableService.assignTableOrder(id, orderId));
    }

    @PutMapping("/{id}/status")
    @PreAuthorize("hasAnyRole('CASHIER', 'CAPTAIN', 'MANAGER', 'ADMIN')")
    public ResponseEntity<RestaurantTable> updateStatus(@PathVariable UUID id, @RequestParam TableStatus status) {
        return ResponseEntity.ok(tableService.updateTableStatus(id, status));
    }

    @PostMapping("/merge")
    @PreAuthorize("hasAnyRole('CAPTAIN', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Void> mergeTables(@RequestParam UUID primaryTableId, @RequestBody List<UUID> secondaryTableIds) {
        tableService.mergeTables(primaryTableId, secondaryTableIds);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/unmerge")
    @PreAuthorize("hasAnyRole('CAPTAIN', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Void> unmergeTables(@RequestParam UUID primaryTableId) {
        tableService.unmergeTables(primaryTableId);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/transfer")
    @PreAuthorize("hasAnyRole('CAPTAIN', 'MANAGER', 'ADMIN')")
    public ResponseEntity<RestaurantTable> transferTable(@RequestParam UUID sourceTableId, @RequestParam UUID destinationTableId) {
        return ResponseEntity.ok(tableService.transferTable(sourceTableId, destinationTableId));
    }

    @PutMapping("/{id}/covers")
    @PreAuthorize("hasAnyRole('CAPTAIN', 'MANAGER', 'ADMIN')")
    public ResponseEntity<RestaurantTable> updateCovers(@PathVariable UUID id, @RequestParam Integer count) {
        RestaurantTable table = tableService.getTableById(id);
        if (table.getCurrentOrderId() == null) {
            throw new RuntimeException("No active order for this table");
        }
        Order order = orderRepository.findById(table.getCurrentOrderId())
                .orElseThrow(() -> new RuntimeException("Order not found"));
        order.setCovers(count);
        orderRepository.save(order);
        return ResponseEntity.ok(table);
    }

    @GetMapping("/analytics/turn-time")
    @PreAuthorize("hasAnyRole('CASHIER', 'CAPTAIN', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Double> getAverageTurnTime() {
        return ResponseEntity.ok(tableService.getAverageTurnTimeMinutes());
    }
}
