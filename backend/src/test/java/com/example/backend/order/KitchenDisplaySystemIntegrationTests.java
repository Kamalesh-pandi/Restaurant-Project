package com.example.backend.order;

import com.example.backend.menu.entity.*;
import com.example.backend.menu.repository.*;
import com.example.backend.order.dto.*;
import com.example.backend.order.entity.*;
import com.example.backend.order.repository.*;
import com.example.backend.order.service.KdsService;
import com.example.backend.order.service.OrderService;
import com.example.backend.table.entity.RestaurantTable;
import com.example.backend.table.entity.TableStatus;
import com.example.backend.table.repository.RestaurantTableRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.UUID;
import com.example.backend.bill.entity.Bill;
import com.example.backend.bill.service.BillService;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@Transactional
public class KitchenDisplaySystemIntegrationTests {

    @Autowired
    private OrderService orderService;

    @Autowired
    private KdsService kdsService;

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private OrderItemRepository orderItemRepository;

    @Autowired
    private RestaurantTableRepository tableRepository;

    @Autowired
    private MenuItemRepository menuItemRepository;

    @Autowired
    private KitchenStationRepository kitchenStationRepository;

    @Autowired
    private BillService billService;

    private UUID outletId;
    private KitchenStation pizzaStation;
    private MenuItem pepperoniPizza;
    private RestaurantTable tableLarge;
    private RestaurantTable tableSmall;

    @BeforeEach
    public void setUp() {
        outletId = UUID.randomUUID();
        orderItemRepository.deleteAll();
        orderRepository.deleteAll();
        tableRepository.deleteAll();
        menuItemRepository.deleteAll();
        kitchenStationRepository.deleteAll();

        // 1. Seed Kitchen Station
        pizzaStation = KitchenStation.builder()
                .name("PIZZA")
                .build();
        pizzaStation = kitchenStationRepository.save(pizzaStation);

        // 2. Seed MenuItem mapped to Pizza Station
        pepperoniPizza = MenuItem.builder()
                .outletId(outletId)
                .name("Pepperoni Pizza")
                .price(BigDecimal.valueOf(300.00))
                .gstRate(BigDecimal.valueOf(5.0))
                .foodType("Non-Veg")
                .isAvailable(true)
                .stationId(pizzaStation.getId())
                .build();
        pepperoniPizza = menuItemRepository.save(pepperoniPizza);

        // 3. Seed Tables
        tableLarge = RestaurantTable.builder()
                .outletId(outletId)
                .tableNumber("T10")
                .capacity(8) // Large table
                .status(TableStatus.AVAILABLE)
                .build();
        tableLarge = tableRepository.save(tableLarge);

        tableSmall = RestaurantTable.builder()
                .outletId(outletId)
                .tableNumber("T2")
                .capacity(2) // Small table
                .status(TableStatus.AVAILABLE)
                .build();
        tableSmall = tableRepository.save(tableSmall);
    }

    @Test
    public void testStationRoutingAndActiveOrdersDisplay() {
        Order order = Order.builder()
                .outletId(outletId)
                .orderType(OrderType.DINE_IN)
                .status(OrderStatus.NEW)
                .build();

        OrderItem item = OrderItem.builder()
                .menuItemId(pepperoniPizza.getItemId())
                .quantity(1)
                .unitPrice(pepperoniPizza.getPrice())
                .status(OrderItemStatus.PENDING)
                .build();

        order = orderService.createOrder(order, Collections.singletonList(item));
        orderService.fireKot(order.getOrderId());

        // Get KDS orders for Pizza Station
        List<KdsItemResponse> kdsOrders = kdsService.getKdsOrdersByStation(pizzaStation.getId());
        assertEquals(1, kdsOrders.size());
        assertEquals("Pepperoni Pizza", kdsOrders.get(0).getMenuItemName());
        assertEquals("GREEN", kdsOrders.get(0).getColorCode()); // Fired just now
    }

    @Test
    public void testCourseBasedFiring() {
        Order order = Order.builder()
                .outletId(outletId)
                .orderType(OrderType.DINE_IN)
                .status(OrderStatus.DRAFT)
                .build();

        OrderItem appItem = OrderItem.builder()
                .menuItemId(pepperoniPizza.getItemId())
                .quantity(1)
                .unitPrice(pepperoniPizza.getPrice())
                .course("APPETIZER")
                .status(OrderItemStatus.PENDING)
                .build();

        OrderItem mainItem = OrderItem.builder()
                .menuItemId(pepperoniPizza.getItemId())
                .quantity(1)
                .unitPrice(pepperoniPizza.getPrice())
                .course("MAIN")
                .status(OrderItemStatus.PENDING)
                .build();

        List<OrderItem> list = new ArrayList<>();
        list.add(appItem);
        list.add(mainItem);

        order = orderService.createOrder(order, list);

        // Fire Appetizer first
        orderService.fireCourse(order.getOrderId(), "APPETIZER");

        List<OrderItem> savedItems = orderItemRepository.findByOrderId(order.getOrderId());
        OrderItem appDb = savedItems.stream().filter(i -> i.getCourse().equals("APPETIZER")).findFirst().orElseThrow();
        OrderItem mainDb = savedItems.stream().filter(i -> i.getCourse().equals("MAIN")).findFirst().orElseThrow();

        // Appetizer should be preparing, Main should remain pending
        assertEquals(OrderItemStatus.PREPARING, appDb.getStatus());
        assertEquals(OrderItemStatus.PENDING, mainDb.getStatus());

        // Fire Main course later
        orderService.fireCourse(order.getOrderId(), "MAIN");
        savedItems = orderItemRepository.findByOrderId(order.getOrderId());
        mainDb = savedItems.stream().filter(i -> i.getCourse().equals("MAIN")).findFirst().orElseThrow();
        assertEquals(OrderItemStatus.PREPARING, mainDb.getStatus());
    }

    @Test
    public void testKdsPriorityDisplaySorting() {
        // Order 1: Small table, dine-in
        Order orderSmall = Order.builder()
                .outletId(outletId)
                .tableId(tableSmall.getTableId())
                .orderType(OrderType.DINE_IN)
                .covers(2)
                .status(OrderStatus.NEW)
                .build();
        OrderItem itemSmall = OrderItem.builder()
                .menuItemId(pepperoniPizza.getItemId())
                .quantity(1)
                .unitPrice(pepperoniPizza.getPrice())
                .status(OrderItemStatus.PENDING)
                .build();
        orderSmall = orderService.createOrder(orderSmall, Collections.singletonList(itemSmall));
        orderService.fireKot(orderSmall.getOrderId());

        // Order 2: Direct delivery order (highest priority +100)
        Order orderAggregator = Order.builder()
                .outletId(outletId)
                .orderType(OrderType.DIRECT_ONLINE)
                .customerName("Direct Online Guest")
                .customerPhone("9876543210")
                .status(OrderStatus.NEW)
                .build();
        OrderItem itemAggregator = OrderItem.builder()
                .menuItemId(pepperoniPizza.getItemId())
                .quantity(1)
                .unitPrice(pepperoniPizza.getPrice())
                .status(OrderItemStatus.PENDING)
                .build();
        orderAggregator = orderService.createOrder(orderAggregator, Collections.singletonList(itemAggregator));
        orderService.fireKot(orderAggregator.getOrderId());

        // Order 3: Large table order (high priority +80)
        Order orderLarge = Order.builder()
                .outletId(outletId)
                .tableId(tableLarge.getTableId())
                .orderType(OrderType.DINE_IN)
                .covers(8)
                .status(OrderStatus.NEW)
                .build();
        OrderItem itemLarge = OrderItem.builder()
                .menuItemId(pepperoniPizza.getItemId())
                .quantity(1)
                .unitPrice(pepperoniPizza.getPrice())
                .status(OrderItemStatus.PENDING)
                .build();
        orderLarge = orderService.createOrder(orderLarge, Collections.singletonList(itemLarge));
        orderService.fireKot(orderLarge.getOrderId());

        // Fetch KDS items
        List<KdsItemResponse> kdsOrders = kdsService.getKdsOrdersByStation(pizzaStation.getId());
        assertEquals(3, kdsOrders.size());

        // Assert sorting order: Aggregator first, Large table second, Small table third
        assertEquals(orderAggregator.getOrderId(), kdsOrders.get(0).getOrderId());
        assertEquals(orderLarge.getOrderId(), kdsOrders.get(1).getOrderId());
        assertEquals(orderSmall.getOrderId(), kdsOrders.get(2).getOrderId());
    }

    @Test
    public void testBumpItemAndOrderReadyAlert() {
        Order order = Order.builder()
                .outletId(outletId)
                .orderType(OrderType.TAKEAWAY)
                .status(OrderStatus.NEW)
                .build();
        OrderItem item = OrderItem.builder()
                .menuItemId(pepperoniPizza.getItemId())
                .quantity(1)
                .unitPrice(pepperoniPizza.getPrice())
                .status(OrderItemStatus.PENDING)
                .build();
        order = orderService.createOrder(order, Collections.singletonList(item));
        orderService.fireKot(order.getOrderId());

        List<OrderItem> activeItems = orderItemRepository.findByOrderId(order.getOrderId());
        assertEquals(1, activeItems.size());
        UUID itemId = activeItems.get(0).getItemId();

        // Bump item
        OrderItem bumped = kdsService.bumpItem(itemId);
        assertEquals(OrderItemStatus.READY, bumped.getStatus());
        assertNotNull(bumped.getPreparedAt());

        // Check order status becomes READY
        Order fetchedOrder = orderRepository.findById(order.getOrderId()).orElseThrow();
        assertEquals(OrderStatus.READY, fetchedOrder.getStatus());
    }

    @Test
    public void testRecalledBumps() {
        Order order = Order.builder()
                .outletId(outletId)
                .orderType(OrderType.TAKEAWAY)
                .status(OrderStatus.NEW)
                .build();
        OrderItem item = OrderItem.builder()
                .menuItemId(pepperoniPizza.getItemId())
                .quantity(1)
                .unitPrice(pepperoniPizza.getPrice())
                .status(OrderItemStatus.PENDING)
                .build();
        order = orderService.createOrder(order, Collections.singletonList(item));
        orderService.fireKot(order.getOrderId());

        UUID itemId = orderItemRepository.findByOrderId(order.getOrderId()).get(0).getItemId();
        kdsService.bumpItem(itemId);

        // Fetch recalled bumps (should have 1 item)
        List<KdsItemResponse> recalled = kdsService.getRecalledBumps(pizzaStation.getId());
        assertEquals(1, recalled.size());
        assertEquals("Pepperoni Pizza", recalled.get(0).getMenuItemName());
    }

    @Test
    public void testKdsPerformanceMetrics() {
        Order order = Order.builder()
                .outletId(outletId)
                .orderType(OrderType.TAKEAWAY)
                .status(OrderStatus.NEW)
                .build();
        OrderItem item = OrderItem.builder()
                .menuItemId(pepperoniPizza.getItemId())
                .quantity(1)
                .unitPrice(pepperoniPizza.getPrice())
                .status(OrderItemStatus.PENDING)
                .build();
        order = orderService.createOrder(order, Collections.singletonList(item));
        orderService.fireKot(order.getOrderId());

        UUID itemId = orderItemRepository.findByOrderId(order.getOrderId()).get(0).getItemId();
        kdsService.bumpItem(itemId);

        KdsPerformanceResponse metrics = kdsService.getPerformanceMetrics(pizzaStation.getId());
        assertEquals(0, metrics.getCurrentOrdersCount()); // 0 active (all bumped)
        assertEquals(1, metrics.getItemsSoldCount()); // 1 item sold/prepared
        assertTrue(metrics.getAveragePrepTimeMinutes() >= 0.0);
    }

    @Test
    public void testOfflineKdsSync() {
        Order order = Order.builder()
                .outletId(outletId)
                .orderType(OrderType.TAKEAWAY)
                .status(OrderStatus.NEW)
                .build();
        OrderItem item = OrderItem.builder()
                .menuItemId(pepperoniPizza.getItemId())
                .quantity(1)
                .unitPrice(pepperoniPizza.getPrice())
                .status(OrderItemStatus.PENDING)
                .build();
        order = orderService.createOrder(order, Collections.singletonList(item));
        orderService.fireKot(order.getOrderId());

        UUID itemId = orderItemRepository.findByOrderId(order.getOrderId()).get(0).getItemId();

        // Perform offline sync
        List<OrderItem> synced = kdsService.syncOfflineBumps(Collections.singletonList(itemId));
        assertEquals(1, synced.size());
        assertEquals(OrderItemStatus.READY, synced.get(0).getStatus());

        Order fetchedOrder = orderRepository.findById(order.getOrderId()).orElseThrow();
        assertEquals(OrderStatus.READY, fetchedOrder.getStatus());
    }

    @Test
    public void testOnlinePaidOrderShowsInKitchenDisplay() {
        // 1. Customer orders online (DELIVERY)
        Order onlineOrder = Order.builder()
                .outletId(outletId)
                .orderType(OrderType.DELIVERY)
                .status(OrderStatus.NEW)
                .customerName("Online Customer")
                .customerPhone("9876543210")
                .deliveryAddress("123 Cloud St")
                .kotFiredAt(LocalDateTime.now())
                .build();

        OrderItem item = OrderItem.builder()
                .menuItemId(pepperoniPizza.getItemId())
                .quantity(2)
                .unitPrice(pepperoniPizza.getPrice())
                .status(OrderItemStatus.PREPARING)
                .build();

        Order createdOrder = orderService.createOrder(onlineOrder, Collections.singletonList(item));
        final UUID orderId = createdOrder.getOrderId();

        // 2. Bill is generated and settled via Online Payment (Razorpay / UPI)
        Bill bill = billService.generateBill(orderId, BigDecimal.ZERO, "9876543210", 0, null);
        assertNotNull(bill);

        Bill settledBill = billService.settleBill(bill.getBillId(), "RAZORPAY", "9876543210");
        assertTrue(settledBill.isSettled());

        // 3. Verify Order status stays PREPARING (so kitchen can cook) and paymentStatus is PAID
        Order updatedOrder = orderRepository.findById(orderId).orElseThrow();
        assertEquals("PAID", updatedOrder.getPaymentStatus());
        assertEquals(OrderStatus.PREPARING, updatedOrder.getStatus());

        // 4. Verify Kitchen Display System shows the paid online order
        List<KdsItemResponse> allKdsOrders = kdsService.getAllKdsOrders();
        assertTrue(allKdsOrders.stream().anyMatch(k -> k.getOrderId().equals(orderId)),
                "Paid online order must appear in getAllKdsOrders()");

        List<KdsItemResponse> stationOrders = kdsService.getKdsOrdersByStation(pizzaStation.getId());
        assertTrue(stationOrders.stream().anyMatch(k -> k.getOrderId().equals(orderId)),
                "Paid online order must appear in getKdsOrdersByStation()");

        KdsItemResponse kdsItem = stationOrders.stream()
                .filter(k -> k.getOrderId().equals(orderId))
                .findFirst().orElseThrow();
        assertEquals("Pepperoni Pizza", kdsItem.getMenuItemName());
        assertEquals(2, kdsItem.getQuantity());
        assertEquals("Online Customer", kdsItem.getCustomerName());

        // 5. Kitchen bumps item to READY
        OrderItem bumped = kdsService.bumpItem(kdsItem.getItemId());
        assertEquals(OrderItemStatus.READY, bumped.getStatus());

        Order finalOrder = orderRepository.findById(orderId).orElseThrow();
        assertEquals(OrderStatus.READY, finalOrder.getStatus(),
                "Once bumped in KDS, order status becomes READY for dispatch/delivery");
    }
}
