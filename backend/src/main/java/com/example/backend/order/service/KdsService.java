package com.example.backend.order.service;

import com.example.backend.delivery.entity.DeliveryPartner;
import com.example.backend.delivery.repository.DeliveryPartnerRepository;
import com.example.backend.delivery.service.DeliveryService;
import com.example.backend.order.service.OrderService;
import com.example.backend.menu.entity.KitchenStation;
import com.example.backend.menu.entity.MenuItem;
import com.example.backend.menu.repository.KitchenStationRepository;
import com.example.backend.menu.repository.MenuItemRepository;
import com.example.backend.order.dto.KdsItemResponse;
import com.example.backend.order.dto.KdsPerformanceResponse;
import com.example.backend.order.entity.*;
import com.example.backend.order.repository.OrderItemRepository;
import com.example.backend.order.repository.OrderRepository;
import com.example.backend.table.entity.RestaurantTable;
import com.example.backend.table.repository.RestaurantTableRepository;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class KdsService {

    private final OrderRepository orderRepository;
    private final OrderItemRepository orderItemRepository;
    private final MenuItemRepository menuItemRepository;
    private final RestaurantTableRepository tableRepository;
    private final SimpMessagingTemplate messagingTemplate;
    private final KitchenStationRepository kitchenStationRepository;
    private final OrderService orderService;
    private final DeliveryService deliveryService;
    private final DeliveryPartnerRepository deliveryPartnerRepository;

    public KdsService(OrderRepository orderRepository,
                      OrderItemRepository orderItemRepository,
                      MenuItemRepository menuItemRepository,
                      RestaurantTableRepository tableRepository,
                      SimpMessagingTemplate messagingTemplate,
                      KitchenStationRepository kitchenStationRepository,
                      OrderService orderService,
                      DeliveryService deliveryService,
                      DeliveryPartnerRepository deliveryPartnerRepository) {
        this.orderRepository = orderRepository;
        this.orderItemRepository = orderItemRepository;
        this.menuItemRepository = menuItemRepository;
        this.tableRepository = tableRepository;
        this.messagingTemplate = messagingTemplate;
        this.kitchenStationRepository = kitchenStationRepository;
        this.orderService = orderService;
        this.deliveryService = deliveryService;
        this.deliveryPartnerRepository = deliveryPartnerRepository;
    }

    public List<KdsItemResponse> getAllKdsOrders() {
        List<Order> activeOrders = orderRepository.findAll().stream()
                .filter(o -> o.getStatus() != OrderStatus.CANCELLED && o.getStatus() != OrderStatus.DRAFT)
                .filter(o -> {
                    if (o.getStatus() == OrderStatus.DELIVERED) return false;
                    // Unpaid online / prepaid orders must NOT be displayed in KDS until payment is completed!
                    boolean isOnlinePrepaid = (o.getOrderType() == OrderType.DELIVERY 
                            || o.getOrderType() == OrderType.DIRECT_ONLINE 
                            || o.getOrderType() == OrderType.TAKEAWAY)
                            && o.getPaymentMethod() != null 
                            && !o.getPaymentMethod().equalsIgnoreCase("COD");
                    if (isOnlinePrepaid && !"PAID".equalsIgnoreCase(o.getPaymentStatus())) {
                        return false;
                    }
                    List<OrderItem> items = orderItemRepository.findByOrderId(o.getOrderId());
                    if (o.getOrderType() == OrderType.DINE_IN && (o.getStatus() == OrderStatus.PAID || o.getStatus() == OrderStatus.SERVED)) {
                        return items.stream().anyMatch(i -> i.getStatus() == OrderItemStatus.PREPARING || i.getStatus() == OrderItemStatus.PENDING);
                    }
                    return items.stream().anyMatch(i -> 
                        i.getStatus() == OrderItemStatus.PREPARING || 
                        i.getStatus() == OrderItemStatus.PENDING ||
                        i.getStatus() == OrderItemStatus.READY
                    );
                })
                .toList();

        List<KdsItemResponse> responses = new ArrayList<>();
        LocalDateTime now = LocalDateTime.now();

        for (Order order : activeOrders) {
            List<OrderItem> items = orderItemRepository.findByOrderId(order.getOrderId());
            for (OrderItem item : items) {
                if (item.getStatus() == OrderItemStatus.VOIDED) continue;
                MenuItem menuItem = menuItemRepository.findById(item.getMenuItemId()).orElse(null);
                RestaurantTable table = order.getTableId() != null ? 
                        tableRepository.findById(order.getTableId()).orElse(null) : null;
                
                LocalDateTime fireTime = order.getKotFiredAt() != null ? order.getKotFiredAt() : (now);
                long elapsed = Duration.between(fireTime, now).toMinutes();
                
                String colorCode = elapsed >= 10 ? "RED" : (elapsed >= 5 ? "AMBER" : "GREEN");

                UUID stId = menuItem != null ? menuItem.getStationId() : null;
                String stName = null;
                if (stId != null) {
                    stName = kitchenStationRepository.findById(stId).map(KitchenStation::getName).orElse(null);
                }

                responses.add(KdsItemResponse.builder()
                        .itemId(item.getItemId())
                        .orderId(order.getOrderId())
                        .menuItemName(menuItem != null ? menuItem.getName() : "Item")
                        .quantity(item.getQuantity())
                        .modifiers(item.getModifiers())
                        .course(item.getCourse())
                        .orderType(order.getOrderType() != null ? order.getOrderType().name() : "DINE_IN")
                        .tableNumber(table != null ? table.getTableNumber() : "N/A")
                        .status(item.getStatus() != null ? item.getStatus().name() : "PENDING")
                        .kotFiredAt(fireTime)
                        .minutesElapsed(elapsed)
                        .colorCode(colorCode)
                        .stationId(stId)
                        .stationName(stName)
                        .notes(order.getDeliveryNotes())
                        .customerName(order.getCustomerName())
                        .customerPhone(order.getCustomerPhone())
                        .orderStatus(order.getStatus() != null ? order.getStatus().name() : null)
                        .deliveryPartnerName(order.getDeliveryPartnerId() != null ? deliveryPartnerRepository.findById(order.getDeliveryPartnerId()).map(DeliveryPartner::getName).orElse(null) : null)
                        .deliveryPartnerPhone(order.getDeliveryPartnerId() != null ? deliveryPartnerRepository.findById(order.getDeliveryPartnerId()).map(DeliveryPartner::getPhone).orElse(null) : null)
                        .build());
            }
        }
        return responses;
    }

    public List<KdsItemResponse> getKdsOrdersByStation(UUID stationId) {
        List<Order> activeOrders = orderRepository.findAll().stream()
                .filter(o -> o.getStatus() != OrderStatus.CANCELLED && o.getStatus() != OrderStatus.DRAFT)
                .filter(o -> {
                    if (o.getStatus() == OrderStatus.DELIVERED) return false;
                    // Unpaid online / prepaid orders must NOT be displayed in KDS until payment is completed!
                    boolean isOnlinePrepaid = (o.getOrderType() == OrderType.DELIVERY 
                            || o.getOrderType() == OrderType.DIRECT_ONLINE 
                            || o.getOrderType() == OrderType.TAKEAWAY)
                            && o.getPaymentMethod() != null 
                            && !o.getPaymentMethod().equalsIgnoreCase("COD");
                    if (isOnlinePrepaid && !"PAID".equalsIgnoreCase(o.getPaymentStatus())) {
                        return false;
                    }
                    List<OrderItem> items = orderItemRepository.findByOrderId(o.getOrderId());
                    if (o.getOrderType() == OrderType.DINE_IN && (o.getStatus() == OrderStatus.PAID || o.getStatus() == OrderStatus.SERVED)) {
                        return items.stream().anyMatch(i -> i.getStatus() == OrderItemStatus.PREPARING || i.getStatus() == OrderItemStatus.PENDING);
                    }
                    return items.stream().anyMatch(i -> 
                        i.getStatus() == OrderItemStatus.PREPARING || 
                        i.getStatus() == OrderItemStatus.PENDING
                    );
                })
                .toList();

        List<KdsItemResponse> responses = new ArrayList<>();
        LocalDateTime now = LocalDateTime.now();

        for (Order order : activeOrders) {
            List<OrderItem> items = orderItemRepository.findByOrderId(order.getOrderId());
            for (OrderItem item : items) {
                // Include active items (PREPARING or PENDING) or recently voided items (within last 10 mins)
                boolean isActive = item.getStatus() == OrderItemStatus.PREPARING || item.getStatus() == OrderItemStatus.PENDING;
                boolean isRecentVoid = item.getStatus() == OrderItemStatus.VOIDED; // for KDS void highlight
                
                if (isActive || isRecentVoid) {
                    MenuItem menuItem = menuItemRepository.findById(item.getMenuItemId()).orElse(null);
                    if (menuItem != null && (menuItem.getStationId() == null || stationId.equals(menuItem.getStationId()))) {
                        RestaurantTable table = order.getTableId() != null ? 
                                tableRepository.findById(order.getTableId()).orElse(null) : null;
                        
                        LocalDateTime fireTime = order.getKotFiredAt() != null ? order.getKotFiredAt() : (now);
                        long elapsed = Duration.between(fireTime, now).toMinutes();
                        
                        // Color coding
                        String colorCode = "GREEN";
                        if (elapsed >= 10) {
                            colorCode = "RED";
                        } else if (elapsed >= 5) {
                            colorCode = "AMBER";
                        }

                        // Priority Scoring
                        int priority = 0;
                        if (order.getOrderType() == OrderType.DIRECT_ONLINE || order.getOrderType() == OrderType.DELIVERY) {
                            priority += 100;
                        }
                        if (order.getCovers() >= 6 || (table != null && table.getCapacity() >= 6)) {
                            priority += 80;
                        }
                        priority += (int) (elapsed * 2);

                        responses.add(KdsItemResponse.builder()
                                .itemId(item.getItemId())
                                .orderId(order.getOrderId())
                                .menuItemName(menuItem.getName())
                                .quantity(item.getQuantity())
                                .modifiers(item.getModifiers())
                                .course(item.getCourse())
                                .orderType(order.getOrderType().name())
                                .tableNumber(table != null ? table.getTableNumber() : "N/A")
                                .status(item.getStatus().name())
                                .kotFiredAt(fireTime)
                                .minutesElapsed(elapsed)
                                .colorCode(colorCode)
                                .priorityScore(priority)
                                .voidReason(item.getVoidReason())
                                .stationId(stationId)
                                .stationName(kitchenStationRepository.findById(stationId).map(KitchenStation::getName).orElse(null))
                                .notes(order.getDeliveryNotes())
                                .customerName(order.getCustomerName())
                                .customerPhone(order.getCustomerPhone())
                                .orderStatus(order.getStatus() != null ? order.getStatus().name() : null)
                                .deliveryPartnerName(order.getDeliveryPartnerId() != null ? deliveryPartnerRepository.findById(order.getDeliveryPartnerId()).map(DeliveryPartner::getName).orElse(null) : null)
                                .deliveryPartnerPhone(order.getDeliveryPartnerId() != null ? deliveryPartnerRepository.findById(order.getDeliveryPartnerId()).map(DeliveryPartner::getPhone).orElse(null) : null)
                                .build());
                    }
                }
            }
        }

        // Sort descending by priorityScore, then oldest first
        responses.sort((r1, r2) -> {
            int scoreCompare = Integer.compare(r2.getPriorityScore(), r1.getPriorityScore());
            if (scoreCompare != 0) {
                return scoreCompare;
            }
            return r1.getKotFiredAt().compareTo(r2.getKotFiredAt());
        });

        return responses;
    }

    @Transactional
    public OrderItem bumpItem(UUID itemId) {
        OrderItem item = orderItemRepository.findById(itemId)
                .orElseThrow(() -> new RuntimeException("OrderItem not found"));
        item.setStatus(OrderItemStatus.READY);
        item.setPreparedAt(LocalDateTime.now());
        OrderItem saved = orderItemRepository.save(item);

        checkAndNotifyOrderReady(item.getOrderId());
        return saved;
    }

    private void checkAndNotifyOrderReady(UUID orderId) {
        List<OrderItem> allItems = orderItemRepository.findByOrderId(orderId);
        boolean allReady = allItems.stream()
                .allMatch(i -> i.getStatus() == OrderItemStatus.READY
                            || i.getStatus() == OrderItemStatus.SERVED
                            || i.getStatus() == OrderItemStatus.VOIDED);
        
        if (allReady) {
            Order order = orderRepository.findById(orderId).orElse(null);
            if (order != null && order.getStatus() != OrderStatus.READY) {
                order.setStatus(OrderStatus.READY);
                orderRepository.save(order);

                // Broadcast WebSocket ready alert to Captain
                RestaurantTable table = order.getTableId() != null ? 
                        tableRepository.findById(order.getTableId()).orElse(null) : null;
                String tableNum = table != null ? table.getTableNumber() : "N/A";
                String alert = String.format("Order Ready Alert: Order ID %s at Table %s is ready for service!", 
                        order.getOrderId(), tableNum);
                
                System.out.println("[KDS ALERT] " + alert);
                
                try {
                    messagingTemplate.convertAndSend("/topic/ready-alerts", alert);
                } catch (Exception e) {
                    // WebSocket ignore in tests
                }
            }
        }
    }

    public List<KdsItemResponse> getRecalledBumps(UUID stationId) {
        List<OrderItem> allItems = orderItemRepository.findAll();
        List<OrderItem> bumped = allItems.stream()
                .filter(i -> (i.getStatus() == OrderItemStatus.READY || i.getStatus() == OrderItemStatus.SERVED) && i.getPreparedAt() != null)
                .toList();

        List<KdsItemResponse> responses = new ArrayList<>();
        for (OrderItem item : bumped) {
            MenuItem menuItem = menuItemRepository.findById(item.getMenuItemId()).orElse(null);
            if (menuItem != null && stationId.equals(menuItem.getStationId())) {
                Order order = orderRepository.findById(item.getOrderId()).orElse(null);
                if (order != null) {
                    RestaurantTable table = order.getTableId() != null ? 
                            tableRepository.findById(order.getTableId()).orElse(null) : null;
                    
                    responses.add(KdsItemResponse.builder()
                            .itemId(item.getItemId())
                            .orderId(order.getOrderId())
                            .menuItemName(menuItem.getName())
                            .quantity(item.getQuantity())
                            .modifiers(item.getModifiers())
                            .course(item.getCourse())
                            .orderType(order.getOrderType().name())
                            .tableNumber(table != null ? table.getTableNumber() : "N/A")
                            .status(item.getStatus().name())
                            .kotFiredAt(order.getKotFiredAt())
                            .preparedAt(item.getPreparedAt())
                            .build());
                }
            }
        }

        // Sort by preparedAt descending
        responses.sort((r1, r2) -> r2.getPreparedAt().compareTo(r1.getPreparedAt()));

        // Return only last 5
        return responses.stream().limit(5).collect(Collectors.toList());
    }

    public KdsPerformanceResponse getPerformanceMetrics(UUID stationId) {
        List<OrderItem> allItems = orderItemRepository.findAll();
        
        // Current preparings at this station
        int currentCount = 0;
        int itemsSoldCount = 0;
        long totalPrepMinutes = 0;
        int prepTimesCount = 0;

        for (OrderItem item : allItems) {
            MenuItem menuItem = menuItemRepository.findById(item.getMenuItemId()).orElse(null);
            if (menuItem != null && stationId.equals(menuItem.getStationId())) {
                if (item.getStatus() == OrderItemStatus.PREPARING) {
                    currentCount++;
                }
                if (item.getStatus() == OrderItemStatus.READY || item.getStatus() == OrderItemStatus.SERVED) {
                    itemsSoldCount++;
                    if (item.getPreparedAt() != null) {
                        Order order = orderRepository.findById(item.getOrderId()).orElse(null);
                        if (order != null && order.getKotFiredAt() != null) {
                            long prepMinutes = Duration.between(order.getKotFiredAt(), item.getPreparedAt()).toMinutes();
                            totalPrepMinutes += prepMinutes;
                            prepTimesCount++;
                        }
                    }
                }
            }
        }

        double avgPrepTime = prepTimesCount == 0 ? 0.0 : (double) totalPrepMinutes / prepTimesCount;

        return KdsPerformanceResponse.builder()
                .currentOrdersCount(currentCount)
                .averagePrepTimeMinutes(avgPrepTime)
                .itemsSoldCount(itemsSoldCount)
                .build();
    }

    @Transactional
    public Order markOrderReady(UUID orderId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found"));
        order.setStatus(OrderStatus.READY);
        Order saved = orderRepository.save(order);
        
        List<OrderItem> items = orderItemRepository.findByOrderId(orderId);
        for (OrderItem item : items) {
            if (item.getStatus() == OrderItemStatus.PENDING || item.getStatus() == OrderItemStatus.PREPARING) {
                item.setStatus(OrderItemStatus.READY);
                item.setPreparedAt(LocalDateTime.now());
                orderItemRepository.save(item);
            }
        }

        orderService.logTimelineEvent(orderId, "FOOD_READY",
                "Food preparation completed. Packed and ready at kitchen counter.", "Kitchen Staff");

        try {
            messagingTemplate.convertAndSend("/topic/orders", saved);
        } catch (Exception ignored) {}
        return saved;
    }

    @Transactional
    public Order markOrderServed(UUID orderId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found"));
        order.setStatus(OrderStatus.SERVED);
        Order saved = orderRepository.save(order);
        
        List<OrderItem> items = orderItemRepository.findByOrderId(orderId);
        for (OrderItem item : items) {
            if (item.getStatus() != OrderItemStatus.VOIDED) {
                item.setStatus(OrderItemStatus.SERVED);
                orderItemRepository.save(item);
            }
        }

        orderService.logTimelineEvent(orderId, "FOOD_SERVED",
                "Food has been prepared and served by the kitchen.", "Kitchen Staff");

        // For delivery orders, automatically assign delivery partner
        if (order.getOrderType() == OrderType.DELIVERY || order.getOrderType() == OrderType.DIRECT_ONLINE) {
            try {
                if (order.getDeliveryPartnerId() == null) {
                    deliveryService.autoAssignOrder(orderId);
                    saved = orderRepository.findById(orderId).orElse(saved);
                }
            } catch (Exception e) {
                System.err.println("[KDS] Auto-assign delivery partner notice: " + e.getMessage());
            }
        }

        try {
            messagingTemplate.convertAndSend("/topic/orders", saved);
        } catch (Exception ignored) {}
        return saved;
    }

    @Transactional
    public OrderItem updateItemStatus(UUID itemId, OrderItemStatus status) {
        OrderItem item = orderItemRepository.findById(itemId)
                .orElseThrow(() -> new RuntimeException("OrderItem not found"));
        item.setStatus(status);
        if (status == OrderItemStatus.READY || status == OrderItemStatus.SERVED) {
            item.setPreparedAt(LocalDateTime.now());
        }
        OrderItem saved = orderItemRepository.save(item);

        if (status == OrderItemStatus.READY) {
            checkAndNotifyOrderReady(item.getOrderId());
        }
        return saved;
    }

    @Transactional
    public List<OrderItem> syncOfflineBumps(List<UUID> bumpedItemIds) {
        List<OrderItem> synced = new ArrayList<>();
        for (UUID id : bumpedItemIds) {
            try {
                synced.add(bumpItem(id));
            } catch (Exception e) {
                // Ignore missing or duplicate IDs, complete whatever matches
            }
        }
        return synced;
    }
}
