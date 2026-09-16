package com.example.backend.bill;

import com.example.backend.bill.dto.*;
import com.example.backend.bill.entity.Bill;
import com.example.backend.bill.entity.BillPayment;
import com.example.backend.bill.repository.BillPaymentRepository;
import com.example.backend.bill.service.BillService;
import com.example.backend.menu.entity.MenuItem;
import com.example.backend.menu.repository.MenuItemRepository;
import com.example.backend.order.entity.*;
import com.example.backend.order.repository.OrderItemRepository;
import com.example.backend.order.repository.OrderRepository;
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
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@Transactional
public class PaymentProcessingIntegrationTests {

    @Autowired
    private OrderService orderService;

    @Autowired
    private BillService billService;

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private OrderItemRepository orderItemRepository;

    @Autowired
    private RestaurantTableRepository tableRepository;

    @Autowired
    private MenuItemRepository menuItemRepository;

    @Autowired
    private BillPaymentRepository billPaymentRepository;

    @Autowired
    private StaffRepository staffRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    private UUID outletId;
    private MenuItem burger;
    private RestaurantTable table1;
    private String managerPin = "1234";

    @BeforeEach
    public void setUp() {
        outletId = UUID.randomUUID();
        orderItemRepository.deleteAll();
        orderRepository.deleteAll();
        tableRepository.deleteAll();
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
        burger = MenuItem.builder()
                .outletId(outletId)
                .name("Veg Burger")
                .price(BigDecimal.valueOf(125.50)) // 125.50 with 5% GST will produce cents
                .gstRate(BigDecimal.valueOf(5.0))
                .foodType("Veg")
                .isAvailable(true)
                .build();
        burger = menuItemRepository.save(burger);
    }

    @Test
    public void testRoundOffCalculationsPerGstRules() {
        Order order = Order.builder()
                .outletId(outletId)
                .orderType(OrderType.TAKEAWAY)
                .status(OrderStatus.NEW)
                .build();

        OrderItem item = OrderItem.builder()
                .menuItemId(burger.getItemId())
                .quantity(1)
                .unitPrice(burger.getPrice())
                .status(OrderItemStatus.PENDING)
                .build();

        order = orderService.createOrder(order, Collections.singletonList(item));
        orderService.fireKot(order.getOrderId());

        // Generate bill
        Bill bill = billService.generateBill(order.getOrderId(), BigDecimal.ZERO, null, null, managerPin);

        // Subtotal = 125.50
        // CGST (2.5%) = 3.14, SGST (2.5%) = 3.14
        // Unrounded total = 131.78
        // Rounded total (HALF_UP) = 132.00
        // Expected Round-off = +0.22
        assertEquals(BigDecimal.valueOf(132.00).setScale(2), bill.getTotal().setScale(2));
        assertEquals(BigDecimal.valueOf(0.22).setScale(2), bill.getRoundOff().setScale(2));
    }

    @Test
    public void testEqualSplitBilling() {
        Order order = Order.builder()
                .outletId(outletId)
                .orderType(OrderType.DINE_IN)
                .status(OrderStatus.NEW)
                .build();

        OrderItem item = OrderItem.builder()
                .menuItemId(burger.getItemId())
                .quantity(2)
                .unitPrice(burger.getPrice())
                .status(OrderItemStatus.PENDING)
                .build();

        order = orderService.createOrder(order, Collections.singletonList(item));
        orderService.fireKot(order.getOrderId());

        // Split equally by 2 guests
        List<Bill> splitBills = billService.splitBillEqually(order.getOrderId(), 2, managerPin);
        assertEquals(2, splitBills.size());

        // Subtotal = 251.00. Each guest subtotal = 125.50
        for (Bill child : splitBills) {
            assertEquals(BigDecimal.valueOf(125.50).setScale(2), child.getSubtotal().setScale(2));
            assertNotNull(child.getBillNumber());
            assertFalse(child.isSettled());
        }
    }

    @Test
    public void testSplitBillByItemSelection() {
        Order order = Order.builder()
                .outletId(outletId)
                .orderType(OrderType.DINE_IN)
                .status(OrderStatus.NEW)
                .build();

        OrderItem item1 = OrderItem.builder()
                .menuItemId(burger.getItemId())
                .quantity(1)
                .unitPrice(burger.getPrice())
                .status(OrderItemStatus.PENDING)
                .build();

        OrderItem item2 = OrderItem.builder()
                .menuItemId(burger.getItemId())
                .quantity(1)
                .unitPrice(burger.getPrice())
                .status(OrderItemStatus.PENDING)
                .build();

        order = orderService.createOrder(order, List.of(item1, item2));
        orderService.fireKot(order.getOrderId());

        List<OrderItem> savedItems = orderItemRepository.findByOrderId(order.getOrderId());
        assertEquals(2, savedItems.size());

        List<List<UUID>> groups = new ArrayList<>();
        groups.add(List.of(savedItems.get(0).getItemId()));
        groups.add(List.of(savedItems.get(1).getItemId()));

        // Split by items (each item is a separate bill)
        List<Bill> splitBills = billService.splitBillByItems(order.getOrderId(), groups, managerPin);
        assertEquals(2, splitBills.size());

        for (Bill child : splitBills) {
            assertEquals(BigDecimal.valueOf(125.50).setScale(2), child.getSubtotal().setScale(2));
        }
    }

    @Test
    public void testSplitPaymentsReconciliationAndTips() {
        Order order = Order.builder()
                .outletId(outletId)
                .orderType(OrderType.TAKEAWAY)
                .status(OrderStatus.NEW)
                .build();

        OrderItem item = OrderItem.builder()
                .menuItemId(burger.getItemId())
                .quantity(2)
                .unitPrice(burger.getPrice())
                .status(OrderItemStatus.PENDING)
                .build();

        order = orderService.createOrder(order, Collections.singletonList(item));
        orderService.fireKot(order.getOrderId());

        Bill bill = billService.generateBill(order.getOrderId(), BigDecimal.ZERO, null, null, managerPin);
        
        // Split payments: Cash: 100.00, UPI: 164.00 (Total = 264.00)
        List<BillPaymentSplitRequest> splits = new ArrayList<>();
        splits.add(new BillPaymentSplitRequest("CASH", BigDecimal.valueOf(100.00), null));
        splits.add(new BillPaymentSplitRequest("UPI", BigDecimal.valueOf(164.00), "TXN-123"));

        SettleBillRequest settleRequest = SettleBillRequest.builder()
                .splits(splits)
                .tipAmount(BigDecimal.valueOf(10.00)) // Tip 10.00
                .cashReceived(BigDecimal.valueOf(100.00))
                .changeGiven(BigDecimal.ZERO)
                .build();

        Bill settled = billService.settleBillSplit(bill.getBillId(), settleRequest);
        assertTrue(settled.isSettled());
        assertEquals(BigDecimal.valueOf(10.00).setScale(2), settled.getTipAmount().setScale(2));

        // Verify payment records saved
        List<BillPayment> dbPayments = billPaymentRepository.findByBillId(bill.getBillId());
        assertEquals(2, dbPayments.size());

        // Verify Cash Drawer Reconciliation
        CashDrawerReconciliation reconciliation = billService.reconcileCashDrawer(LocalDate.now(), BigDecimal.valueOf(500.00));
        // Expected Cash = 500.00 starting + 100.00 cash payment = 600.00
        assertEquals(BigDecimal.valueOf(600.00).setScale(2), reconciliation.getExpectedCashInDrawer().setScale(2));

        // Verify Z-Report total tips
        DayEndReport report = billService.generateZReport(LocalDate.now(), UUID.randomUUID());
        assertEquals(BigDecimal.valueOf(10.00).setScale(2), report.getTotalTips().setScale(2));
    }

    @Test
    public void testThermalAndDigitalReceipts() {
        Order order = Order.builder()
                .outletId(outletId)
                .orderType(OrderType.TAKEAWAY)
                .status(OrderStatus.NEW)
                .build();

        OrderItem item = OrderItem.builder()
                .menuItemId(burger.getItemId())
                .quantity(1)
                .unitPrice(burger.getPrice())
                .status(OrderItemStatus.PENDING)
                .build();

        order = orderService.createOrder(order, Collections.singletonList(item));
        orderService.fireKot(order.getOrderId());

        Bill bill = billService.generateBill(order.getOrderId(), BigDecimal.ZERO, null, null, managerPin);

        // Verify receipt text contains key labels
        String receipt = billService.getReceiptText(bill.getBillId());
        assertTrue(receipt.contains("DELUXE DINER"));
        assertTrue(receipt.contains("FSSAI Lic No: FSSAI-12345678901234"));
        assertTrue(receipt.contains("GSTIN: GSTIN-27AAAAA1111A1Z1"));
        assertTrue(receipt.contains("Veg Burger"));

        // Verify digital receipt link contains bill ID
        String digitalLink = billService.sendDigitalReceipt(bill.getBillId(), "9999999999");
        assertTrue(digitalLink.contains(bill.getBillId().toString()));
    }

    @Test
    public void testVoidBillAndRefundSimulation() {
        Order order = Order.builder()
                .outletId(outletId)
                .orderType(OrderType.TAKEAWAY)
                .status(OrderStatus.NEW)
                .build();

        OrderItem item = OrderItem.builder()
                .menuItemId(burger.getItemId())
                .quantity(1)
                .unitPrice(burger.getPrice())
                .status(OrderItemStatus.PENDING)
                .build();

        order = orderService.createOrder(order, Collections.singletonList(item));
        orderService.fireKot(order.getOrderId());

        Bill bill = billService.generateBill(order.getOrderId(), BigDecimal.ZERO, null, null, managerPin);

        // Void bill (manager pin authenticated, should print refund simulation details)
        assertDoesNotThrow(() -> billService.voidBill(bill.getBillId(), managerPin));
    }
}
