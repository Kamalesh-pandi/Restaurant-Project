package com.example.backend.order.controller;

import com.example.backend.order.dto.OrderItemSplitRequest;
import com.example.backend.order.dto.OrderRequest;
import com.example.backend.order.entity.Order;
import com.example.backend.order.entity.OrderItem;
import com.example.backend.order.entity.OrderStatus;
import com.example.backend.order.entity.OrderTimelineEvent;
import com.example.backend.order.repository.OrderRepository;
import com.example.backend.order.repository.OrderTimelineRepository;
import com.example.backend.order.service.OrderService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/orders")
public class OrderController {

    private final OrderService orderService;
    private final OrderRepository orderRepository;
    private final OrderTimelineRepository orderTimelineRepository;

    public OrderController(OrderService orderService, OrderRepository orderRepository, OrderTimelineRepository orderTimelineRepository) {
        this.orderService = orderService;
        this.orderRepository = orderRepository;
        this.orderTimelineRepository = orderTimelineRepository;
    }

    @GetMapping
    public ResponseEntity<List<Order>> getAllOrders() {
        return ResponseEntity.ok(orderService.getAllOrders());
    }

    @GetMapping("/{id}")
    public ResponseEntity<Order> getOrderById(@PathVariable UUID id) {
        return ResponseEntity.ok(orderService.getOrderById(id));
    }

    @GetMapping("/{id}/items")
    public ResponseEntity<List<OrderItem>> getOrderItems(@PathVariable UUID id) {
        return ResponseEntity.ok(orderService.getOrderItems(id));
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('CASHIER', 'CAPTAIN', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Order> createOrder(@Valid @RequestBody OrderRequest request) {
        Order order = orderService.createOrder(request.getOrder(), request.getItems());
        return ResponseEntity.status(HttpStatus.CREATED).body(order);
    }

    @PutMapping("/{id}/fire-kot")
    @PreAuthorize("hasAnyRole('CASHIER', 'CAPTAIN', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Order> fireKot(@PathVariable UUID id) {
        return ResponseEntity.ok(orderService.fireKot(id));
    }

    @DeleteMapping("/items/{itemId}")
    @PreAuthorize("hasAnyRole('CASHIER', 'CAPTAIN', 'MANAGER', 'ADMIN')")
    public ResponseEntity<OrderItem> voidOrderItem(@PathVariable UUID itemId, @RequestParam String managerPin) {
        return ResponseEntity.ok(orderService.voidOrderItem(itemId, managerPin));
    }

    @GetMapping("/drafts/table/{tableId}")
    @PreAuthorize("hasAnyRole('CAPTAIN', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<Order>> getDraftOrdersByTable(@PathVariable UUID tableId) {
        return ResponseEntity.ok(orderRepository.findByStatusAndTableId(OrderStatus.DRAFT, tableId));
    }

    @GetMapping("/drafts/token/{token}")
    @PreAuthorize("hasAnyRole('CASHIER', 'CAPTAIN', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<Order>> getDraftOrdersByToken(@PathVariable String token) {
        return ResponseEntity.ok(orderRepository.findByStatusAndTokenNumber(OrderStatus.DRAFT, token));
    }

    @PutMapping("/{id}/modify")
    @PreAuthorize("hasAnyRole('CAPTAIN', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Order> modifyOrderItems(@PathVariable UUID id, @RequestBody List<OrderItem> proposedItems, @RequestParam(required = false) String managerPin) {
        return ResponseEntity.ok(orderService.modifyOrderItems(id, proposedItems, managerPin));
    }

    @PostMapping("/{id}/split")
    @PreAuthorize("hasAnyRole('CASHIER', 'CAPTAIN', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Order> splitOrder(@PathVariable UUID id, @RequestBody List<OrderItemSplitRequest> splitRequests) {
        return ResponseEntity.ok(orderService.splitOrder(id, splitRequests));
    }

    @PutMapping("/items/{orderItemId}/discount")
    @PreAuthorize("hasAnyRole('CAPTAIN', 'MANAGER', 'ADMIN')")
    public ResponseEntity<OrderItem> applyItemDiscount(@PathVariable UUID orderItemId, @RequestParam BigDecimal discountAmount, @RequestParam String managerPin) {
        return ResponseEntity.ok(orderService.applyItemDiscount(orderItemId, discountAmount, managerPin));
    }

    @PutMapping("/items/{orderItemId}/complimentary")
    @PreAuthorize("hasAnyRole('CAPTAIN', 'MANAGER', 'ADMIN')")
    public ResponseEntity<OrderItem> markItemComplimentary(@PathVariable UUID orderItemId, @RequestParam String managerPin) {
        return ResponseEntity.ok(orderService.markItemComplimentary(orderItemId, managerPin));
    }

    @GetMapping("/{id}/timeline")
    @PreAuthorize("hasAnyRole('CAPTAIN', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<OrderTimelineEvent>> getOrderTimeline(@PathVariable UUID id) {
        return ResponseEntity.ok(orderTimelineRepository.findByOrderIdOrderByTimestampAsc(id));
    }

    @PutMapping("/{id}/fire-course")
    @PreAuthorize("hasAnyRole('CASHIER', 'CAPTAIN', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Order> fireCourse(@PathVariable UUID id, @RequestParam String course) {
        return ResponseEntity.ok(orderService.fireCourse(id, course));
    }
}
