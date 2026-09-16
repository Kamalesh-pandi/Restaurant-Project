package com.example.backend.order;

import com.example.backend.bill.entity.Bill;
import com.example.backend.bill.service.BillService;
import com.example.backend.menu.entity.*;
import com.example.backend.menu.repository.*;
import com.example.backend.order.dto.OrderItemSplitRequest;
import com.example.backend.order.entity.*;
import com.example.backend.order.repository.*;
import com.example.backend.order.service.OrderEscalationScheduler;
import com.example.backend.order.service.OrderService;
import com.example.backend.report.entity.DayEndReport;
import com.example.backend.staff.entity.Staff;
import com.example.backend.staff.entity.StaffRole;
import com.example.backend.staff.repository.StaffRepository;
import com.example.backend.table.entity.RestaurantTable;
import com.example.backend.table.entity.TableStatus;
import com.example.backend.table.repository.RestaurantTableRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@Transactional
public class OrderManagementIntegrationTests {

    @Autowired
    private OrderService orderService;

    @Autowired
    private BillService billService;

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private OrderItemRepository orderItemRepository;

    @Autowired
    private OrderTimelineRepository orderTimelineRepository;

    @Autowired
    private RestaurantTableRepository tableRepository;

    @Autowired
    private MenuItemRepository menuItemRepository;

    @Autowired
    private ModifierGroupRepository modifierGroupRepository;

    @Autowired
    private ModifierOptionRepository modifierOptionRepository;

    @Autowired
    private StaffRepository staffRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private OrderEscalationScheduler orderEscalationScheduler;

    private UUID outletId;
    private MenuItem pizza;
    private ModifierGroup extraCheeseGroup;
    private ModifierOption doubleCheese;
    private RestaurantTable table1;
    private String managerPin = "1234";

    @BeforeEach
    public void setUp() {
        outletId = UUID.randomUUID();
        orderItemRepository.deleteAll();
        orderTimelineRepository.deleteAll();
        orderRepository.deleteAll();
        tableRepository.deleteAll();
        modifierOptionRepository.deleteAll();
        modifierGroupRepository.deleteAll();
        menuItemRepository.deleteAll();
        staffRepository.deleteAll();

        // Seed Manager
        Staff manager = Staff.builder()
                .outletId(outletId)
                .name("ManagerJohn")
                .pinHash(passwordEncoder.encode(managerPin))
                .role(StaffRole.MANAGER)
                .isActive(true)
                .build();
        staffRepository.save(manager);

        // Seed Table
        table1 = RestaurantTable.builder()
                .outletId(outletId)
                .tableNumber("T1")
                .capacity(4)
                .status(TableStatus.AVAILABLE)
                .build();
        table1 = tableRepository.save(table1);

        // Seed Menu Item
        pizza = MenuItem.builder()
                .outletId(outletId)
                .name("Veggie Pizza")
                .price(BigDecimal.valueOf(250.00))
                .gstRate(BigDecimal.valueOf(5.0))
                .foodType("Veg")
                .isAvailable(true)
                .build();
        pizza = menuItemRepository.save(pizza);

        // Seed Modifier Group (Mandatory, min=1, max=1)
        extraCheeseGroup = ModifierGroup.builder()
                .menuItemId(pizza.getItemId())
                .name("Cheese Options")
                .isMandatory(true)
                .minSelections(1)
                .maxSelections(1)
                .build();
        extraCheeseGroup = modifierGroupRepository.save(extraCheeseGroup);

        // Seed Modifier Option
        doubleCheese = ModifierOption.builder()
                .modifierGroupId(extraCheeseGroup.getModifierGroupId())
                .name("Double Cheese")
                .price(BigDecimal.valueOf(50.00))
                .isAvailable(true)
                .build();
        doubleCheese = modifierOptionRepository.save(doubleCheese);
    }

    @Test
    public void testCreateDraftOrderAndFireKot() {
        Order draftOrder = Order.builder()
                .outletId(outletId)
                .tableId(table1.getTableId())
                .orderType(OrderType.DINE_IN)
                .status(OrderStatus.DRAFT)
                .build();

        OrderItem item = OrderItem.builder()
                .menuItemId(pizza.getItemId())
                .quantity(1)
                .unitPrice(pizza.getPrice())
                .modifiers("Double Cheese")
                .status(OrderItemStatus.PENDING)
                .build();

        Order saved = orderService.createOrder(draftOrder, Collections.singletonList(item));
        assertEquals(OrderStatus.DRAFT, saved.getStatus());

        RestaurantTable fetchedTable = tableRepository.findById(table1.getTableId()).orElseThrow();
        assertEquals(TableStatus.AVAILABLE, fetchedTable.getStatus());

        Order fired = orderService.fireKot(saved.getOrderId());
        assertEquals(OrderStatus.PREPARING, fired.getStatus());
        assertNotNull(fired.getKotFiredAt());

        fetchedTable = tableRepository.findById(table1.getTableId()).orElseThrow();
        assertEquals(TableStatus.OCCUPIED, fetchedTable.getStatus());
        assertEquals(fired.getOrderId(), fetchedTable.getCurrentOrderId());

        List<OrderTimelineEvent> timeline = orderTimelineRepository.findByOrderIdOrderByTimestampAsc(fired.getOrderId());
        assertFalse(timeline.isEmpty());
        assertTrue(timeline.stream().anyMatch(e -> e.getEventType().equals("KOT_FIRED")));
    }

    @Test
    public void testModifierValidationConstraints() {
        Order order = Order.builder()
                .outletId(outletId)
                .orderType(OrderType.TAKEAWAY)
                .status(OrderStatus.NEW)
                .build();

        OrderItem invalidItemMissing = OrderItem.builder()
                .menuItemId(pizza.getItemId())
                .quantity(1)
                .unitPrice(pizza.getPrice())
                .modifiers("")
                .status(OrderItemStatus.PENDING)
                .build();

        assertThrows(RuntimeException.class, () -> orderService.createOrder(order, Collections.singletonList(invalidItemMissing)));

        OrderItem invalidItemExceeding = OrderItem.builder()
                .menuItemId(pizza.getItemId())
                .quantity(1)
                .unitPrice(pizza.getPrice())
                .modifiers("Double Cheese, Extra Cheese Option")
                .status(OrderItemStatus.PENDING)
                .build();

        modifierOptionRepository.save(ModifierOption.builder()
                .modifierGroupId(extraCheeseGroup.getModifierGroupId())
                .name("Extra Cheese Option")
                .price(BigDecimal.valueOf(40.00))
                .isAvailable(true)
                .build());

        assertThrows(RuntimeException.class, () -> orderService.createOrder(order, Collections.singletonList(invalidItemExceeding)));
    }

    @Test
    public void testOrderSplitting() {
        Order originalOrder = Order.builder()
                .outletId(outletId)
                .tableId(table1.getTableId())
                .orderType(OrderType.DINE_IN)
                .status(OrderStatus.NEW)
                .build();

        OrderItem item1 = OrderItem.builder()
                .menuItemId(pizza.getItemId())
                .quantity(2)
                .unitPrice(pizza.getPrice())
                .modifiers("Double Cheese")
                .status(OrderItemStatus.PENDING)
                .build();

        originalOrder = orderService.createOrder(originalOrder, Collections.singletonList(item1));
        List<OrderItem> savedItems = orderItemRepository.findByOrderId(originalOrder.getOrderId());
        assertEquals(1, savedItems.size());
        OrderItem savedItem = savedItems.get(0);

        OrderItemSplitRequest splitRequest = new OrderItemSplitRequest(savedItem.getItemId(), 1);
        Order splitOrder = orderService.splitOrder(originalOrder.getOrderId(), Collections.singletonList(splitRequest));

        assertNotNull(splitOrder.getOrderId());
        assertNotEquals(originalOrder.getOrderId(), splitOrder.getOrderId());

        OrderItem updatedItem = orderItemRepository.findById(savedItem.getItemId()).orElseThrow();
        assertEquals(1, updatedItem.getQuantity());

        List<OrderItem> splitItems = orderItemRepository.findByOrderId(splitOrder.getOrderId());
        assertEquals(1, splitItems.size());
        assertEquals(1, splitItems.get(0).getQuantity());

        List<OrderTimelineEvent> events = orderTimelineRepository.findByOrderIdOrderByTimestampAsc(originalOrder.getOrderId());
        assertTrue(events.stream().anyMatch(e -> e.getEventType().equals("SPLIT")));
    }

    @Test
    public void testItemDiscountsAndComplimentaryItems() {
        Order order = Order.builder()
                .outletId(outletId)
                .orderType(OrderType.TAKEAWAY)
                .status(OrderStatus.NEW)
                .build();

        OrderItem item = OrderItem.builder()
                .menuItemId(pizza.getItemId())
                .quantity(2)
                .unitPrice(pizza.getPrice())
                .modifiers("Double Cheese")
                .status(OrderItemStatus.PENDING)
                .build();

        order = orderService.createOrder(order, Collections.singletonList(item));
        OrderItem dbItem = orderItemRepository.findByOrderId(order.getOrderId()).get(0);

        OrderItem discounted = orderService.applyItemDiscount(dbItem.getItemId(), BigDecimal.valueOf(50.00), managerPin);
        assertEquals(BigDecimal.valueOf(50.00), discounted.getDiscountAmount());

        Bill bill1 = billService.generateBill(order.getOrderId(), BigDecimal.ZERO, null, null, managerPin);
        assertEquals(BigDecimal.valueOf(450.00).setScale(2), bill1.getSubtotal().setScale(2));

        OrderItem complimentary = orderService.markItemComplimentary(dbItem.getItemId(), managerPin);
        assertTrue(complimentary.isComplimentary());

        billService.voidBill(bill1.getBillId(), managerPin);
        Bill bill2 = billService.generateBill(order.getOrderId(), BigDecimal.ZERO, null, null, managerPin);
        assertEquals(BigDecimal.ZERO.setScale(2), bill2.getSubtotal().setScale(2));
        assertEquals(BigDecimal.ZERO.setScale(2), bill2.getTotal().setScale(2));

        billService.settleBill(bill2.getBillId(), "Cash", null);

        DayEndReport zReport = billService.generateZReport(LocalDate.now(), UUID.randomUUID());
        assertEquals(BigDecimal.valueOf(500.00).setScale(2), zReport.getTotalComplimentaryValue().setScale(2));
    }

    @Test
    public void testKotModifications() {
        Order order = Order.builder()
                .outletId(outletId)
                .tableId(table1.getTableId())
                .orderType(OrderType.DINE_IN)
                .status(OrderStatus.NEW)
                .build();

        OrderItem item = OrderItem.builder()
                .menuItemId(pizza.getItemId())
                .quantity(2)
                .unitPrice(pizza.getPrice())
                .modifiers("Double Cheese")
                .status(OrderItemStatus.PENDING)
                .build();

        order = orderService.createOrder(order, Collections.singletonList(item));
        orderService.fireKot(order.getOrderId());

        MenuItem rolls = menuItemRepository.save(MenuItem.builder()
                .outletId(outletId)
                .name("Spring Rolls")
                .price(BigDecimal.valueOf(100.00))
                .gstRate(BigDecimal.valueOf(5.0))
                .foodType("Veg")
                .isAvailable(true)
                .build());

        List<OrderItem> proposed = new ArrayList<>();
        proposed.add(OrderItem.builder()
                .menuItemId(pizza.getItemId())
                .quantity(1)
                .modifiers("Double Cheese")
                .unitPrice(pizza.getPrice())
                .build());
        proposed.add(OrderItem.builder()
                .menuItemId(rolls.getItemId())
                .quantity(3)
                .modifiers("")
                .unitPrice(rolls.getPrice())
                .build());

        orderService.modifyOrderItems(order.getOrderId(), proposed, managerPin);

        List<OrderItem> activeItems = orderItemRepository.findByOrderId(order.getOrderId());
        assertEquals(2, activeItems.size());
        
        OrderItem updatedPizza = activeItems.stream().filter(i -> i.getMenuItemId().equals(pizza.getItemId())).findFirst().orElseThrow();
        assertEquals(1, updatedPizza.getQuantity());

        OrderItem addedRolls = activeItems.stream().filter(i -> i.getMenuItemId().equals(rolls.getItemId())).findFirst().orElseThrow();
        assertEquals(3, addedRolls.getQuantity());
    }

    @Test
    public void testOrderEscalationScheduler() {
        Order delayedOrder = Order.builder()
                .outletId(outletId)
                .orderType(OrderType.TAKEAWAY)
                .status(OrderStatus.PREPARING)
                .kotFiredAt(LocalDateTime.now().minusMinutes(15))
                .build();
        orderRepository.save(delayedOrder);

        assertDoesNotThrow(() -> orderEscalationScheduler.checkForPendingKitchenEscalations());
    }
}
