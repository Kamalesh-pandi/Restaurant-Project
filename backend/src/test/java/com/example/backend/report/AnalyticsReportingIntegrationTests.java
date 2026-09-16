package com.example.backend.report;

import com.example.backend.bill.entity.Bill;
import com.example.backend.bill.repository.BillRepository;
import com.example.backend.customer.entity.Customer;
import com.example.backend.customer.repository.CustomerRepository;
import com.example.backend.menu.entity.MenuItem;
import com.example.backend.menu.repository.MenuItemRepository;
import com.example.backend.order.entity.*;
import com.example.backend.order.repository.OrderItemRepository;
import com.example.backend.order.repository.OrderRepository;
import com.example.backend.report.dto.*;
import com.example.backend.report.entity.DayEndReport;
import com.example.backend.report.service.AnalyticsService;
import com.example.backend.staff.dto.StaffPerformanceResponse;
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
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@Transactional
public class AnalyticsReportingIntegrationTests {

    @Autowired
    private AnalyticsService analyticsService;

    @Autowired
    private BillRepository billRepository;

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private OrderItemRepository orderItemRepository;

    @Autowired
    private MenuItemRepository menuItemRepository;

    @Autowired
    private RestaurantTableRepository tableRepository;

    @Autowired
    private CustomerRepository customerRepository;

    @Autowired
    private StaffRepository staffRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    private UUID outletId;
    private MenuItem itemBurger;
    private Order order1;
    private Bill bill1;

    @BeforeEach
    public void setUp() {
        outletId = UUID.randomUUID();
        billRepository.deleteAll();
        orderItemRepository.deleteAll();
        orderRepository.deleteAll();
        menuItemRepository.deleteAll();
        tableRepository.deleteAll();
        customerRepository.deleteAll();
        staffRepository.deleteAll();

        // Seed Staff
        Staff staff = Staff.builder()
                .outletId(outletId)
                .name("Analytics Captain")
                .pinHash(passwordEncoder.encode("1234"))
                .role(StaffRole.CAPTAIN)
                .isActive(true)
                .build();
        staff = staffRepository.save(staff);

        // Seed Table
        RestaurantTable table = RestaurantTable.builder()
                .outletId(outletId)
                .tableNumber("T1")
                .capacity(4)
                .status(TableStatus.AVAILABLE)
                .build();
        table = tableRepository.save(table);

        // Seed Menu Item
        itemBurger = MenuItem.builder()
                .outletId(outletId)
                .name("Super Burger")
                .price(BigDecimal.valueOf(150.00))
                .gstRate(BigDecimal.valueOf(5.0))
                .foodType("Veg")
                .isAvailable(true)
                .build();
        itemBurger = menuItemRepository.save(itemBurger);

        // Seed Order
        order1 = Order.builder()
                .outletId(outletId)
                .orderType(OrderType.DINE_IN)
                .tableId(table.getTableId())
                .captainId(staff.getStaffId())
                .status(OrderStatus.PAID)
                .covers(2)
                .seatedAt(LocalDateTime.now().minusMinutes(45))
                .billedAt(LocalDateTime.now())
                .build();
        order1 = orderRepository.save(order1);

        OrderItem orderItem = OrderItem.builder()
                .orderId(order1.getOrderId())
                .menuItemId(itemBurger.getItemId())
                .quantity(2)
                .unitPrice(itemBurger.getPrice())
                .status(OrderItemStatus.SERVED)
                .build();
        orderItemRepository.save(orderItem);

        // Seed Bill
        bill1 = Bill.builder()
                .orderId(order1.getOrderId())
                .billNumber("BILL-990011")
                .subtotal(BigDecimal.valueOf(300.00))
                .cgst(BigDecimal.valueOf(7.50))
                .sgst(BigDecimal.valueOf(7.50))
                .discount(BigDecimal.ZERO)
                .loyaltyDiscount(BigDecimal.ZERO)
                .roundOff(BigDecimal.ZERO)
                .total(BigDecimal.valueOf(315.00))
                .paymentMethod("CASH")
                .isSettled(true)
                .settledAt(LocalDateTime.now())
                .createdAt(LocalDateTime.now())
                .build();
        billRepository.save(bill1);
    }

    @Test
    public void testDailySalesSummaryAndXReport() {
        DailySalesSummaryResponse sales = analyticsService.getDailySalesSummary(LocalDate.now().minusDays(1), LocalDate.now().plusDays(1), outletId);
        assertEquals(BigDecimal.valueOf(315.00).setScale(2), sales.getGmv().setScale(2));
        assertEquals(2, sales.getTotalCovers());

        XReportResponse xReport = analyticsService.getXReport(outletId);
        assertNotNull(xReport.getShiftStartTime());
        assertEquals(BigDecimal.valueOf(315.00).setScale(2), xReport.getLiveSales().setScale(2));
    }

    @Test
    public void testZReportGeneration() {
        DayEndReport zReport = analyticsService.generateZReport(LocalDate.now(), outletId, UUID.randomUUID());
        assertNotNull(zReport.getReportId());
        assertEquals(BigDecimal.valueOf(315.00).setScale(2), zReport.getTotalSales().setScale(2));
        assertEquals(2, zReport.getTotalCovers());
    }

    @Test
    public void testItemPerformanceAndFoodCostReport() {
        ItemPerformanceResponse itemPerf = analyticsService.getItemPerformance(LocalDate.now(), LocalDate.now(), outletId, null);
        assertFalse(itemPerf.getTop10ByUnits().isEmpty());
        assertEquals("Super Burger", itemPerf.getTop10ByUnits().get(0).getItemName());

        Map<String, Object> foodCost = analyticsService.getFoodCostReport(outletId);
        assertNotNull(foodCost.get("totalSalesValue"));
    }

    @Test
    public void testTableAndDeliveryAnalytics() {
        TableAnalyticsResponse tableAnalytics = analyticsService.getTableAnalytics(outletId);
        assertTrue(tableAnalytics.getAverageTableTurnTimeMinutes() > 0);

        DeliveryAnalyticsResponse deliveryReport = analyticsService.getDeliveryReport(outletId);
        assertNotNull(deliveryReport);
    }

    @Test
    public void testCustomerAnalyticsAndStaffProductivity() {
        Customer c = Customer.builder()
                .phone("9911223344")
                .name("Report Guest")
                .totalVisits(2)
                .totalSpend(BigDecimal.valueOf(500.00))
                .build();
        customerRepository.save(c);

        CustomerAnalyticsReportResponse customerReport = analyticsService.getCustomerAnalyticsReport();
        assertTrue(customerReport.getReturningVisits() >= 1);

        List<StaffPerformanceResponse> staffReport = analyticsService.getStaffProductivityReport(outletId);
        assertFalse(staffReport.isEmpty());
    }
}
