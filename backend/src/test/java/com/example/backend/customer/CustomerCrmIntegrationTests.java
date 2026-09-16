package com.example.backend.customer;

import com.example.backend.bill.entity.Bill;
import com.example.backend.bill.service.BillService;
import com.example.backend.customer.dto.*;
import com.example.backend.customer.entity.*;
import com.example.backend.customer.repository.*;
import com.example.backend.customer.service.CustomerService;
import com.example.backend.menu.entity.MenuItem;
import com.example.backend.menu.repository.MenuItemRepository;
import com.example.backend.order.entity.*;
import com.example.backend.order.repository.*;
import com.example.backend.order.service.OrderService;
import com.example.backend.staff.entity.Staff;
import com.example.backend.staff.entity.StaffRole;
import com.example.backend.staff.repository.StaffRepository;
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
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@Transactional
public class CustomerCrmIntegrationTests {

    @Autowired
    private CustomerService customerService;

    @Autowired
    private CustomerRepository customerRepository;

    @Autowired
    private CustomerVisitRepository customerVisitRepository;

    @Autowired
    private OrderService orderService;

    @Autowired
    private BillService billService;

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private OrderItemRepository orderItemRepository;

    @Autowired
    private MenuItemRepository menuItemRepository;

    @Autowired
    private StaffRepository staffRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    private UUID outletId;
    private MenuItem pasta;
    private String managerPin = "1234";

    @BeforeEach
    public void setUp() {
        outletId = UUID.randomUUID();
        customerVisitRepository.deleteAll();
        customerRepository.deleteAll();
        orderItemRepository.deleteAll();
        orderRepository.deleteAll();
        menuItemRepository.deleteAll();
        staffRepository.deleteAll();

        // Seed Manager
        Staff manager = Staff.builder()
                .outletId(outletId)
                .name("ManagerBob")
                .pinHash(passwordEncoder.encode(managerPin))
                .role(StaffRole.MANAGER)
                .isActive(true)
                .build();
        staffRepository.save(manager);

        // Seed Menu Item
        pasta = MenuItem.builder()
                .outletId(outletId)
                .name("Alfredo Pasta")
                .price(BigDecimal.valueOf(250.00))
                .gstRate(BigDecimal.valueOf(5.0))
                .foodType("Veg")
                .isAvailable(true)
                .build();
        pasta = menuItemRepository.save(pasta);
    }

    @Test
    public void testCustomerRegistration() {
        CustomerRequest req = CustomerRequest.builder()
                .phone("9876543210")
                .name("John Customer")
                .email("john@example.com")
                .birthday(LocalDate.of(1990, 5, 20))
                .build();

        CustomerResponse registered = customerService.createCustomer(req);
        assertNotNull(registered.getCustomerId());
        assertEquals("John Customer", registered.getName());
        assertEquals("john@example.com", registered.getEmail());
    }

    @Test
    public void testLoyaltyPointsEarningAndRedemptionOnBilling() {
        // 1. Register customer
        CustomerRequest req = CustomerRequest.builder()
                .phone("9998887770")
                .name("Loyal Sam")
                .build();
        customerService.createCustomer(req);

        // 2. Create order & bill (Spend: 500.00 -> Earn 50 points)
        Order order = Order.builder()
                .outletId(outletId)
                .orderType(OrderType.TAKEAWAY)
                .status(OrderStatus.NEW)
                .build();

        OrderItem item = OrderItem.builder()
                .menuItemId(pasta.getItemId())
                .quantity(2)
                .unitPrice(pasta.getPrice())
                .status(OrderItemStatus.PENDING)
                .build();

        order = orderService.createOrder(order, Collections.singletonList(item));
        orderService.fireKot(order.getOrderId());

        Bill bill = billService.generateBill(order.getOrderId(), BigDecimal.ZERO, null, null, managerPin);
        billService.settleBill(bill.getBillId(), "CASH", "9998887770");

        Customer updatedCustomer = customerRepository.findByPhone("9998887770").orElseThrow();
        assertEquals(52, updatedCustomer.getLoyaltyPoints()); // 500 subtotal + GST = 525.00 total -> 52 points
        assertEquals(1, updatedCustomer.getTotalVisits());

        // 3. Redeem 50 points on next order (50 points = 5.00 discount)
        Order order2 = Order.builder()
                .outletId(outletId)
                .orderType(OrderType.TAKEAWAY)
                .status(OrderStatus.NEW)
                .build();

        OrderItem item2 = OrderItem.builder()
                .menuItemId(pasta.getItemId())
                .quantity(1)
                .unitPrice(pasta.getPrice())
                .status(OrderItemStatus.PENDING)
                .build();

        order2 = orderService.createOrder(order2, Collections.singletonList(item2));
        orderService.fireKot(order2.getOrderId());

        Bill bill2 = billService.generateBill(order2.getOrderId(), BigDecimal.ZERO, "9998887770", 50, managerPin);
        assertEquals(BigDecimal.valueOf(5.00).setScale(2), bill2.getLoyaltyDiscount().setScale(2));

        Customer redeemedCustomer = customerRepository.findByPhone("9998887770").orElseThrow();
        assertEquals(2, redeemedCustomer.getLoyaltyPoints()); // 52 - 50 = 2 remaining
        assertEquals(50, redeemedCustomer.getPointsRedeemed());
    }

    @Test
    public void testVisitHistoryAndFeedbackSubmission() {
        Customer customer = Customer.builder()
                .phone("9112233445")
                .name("Feedback Dave")
                .totalSpend(BigDecimal.ZERO)
                .build();
        customer = customerRepository.save(customer);

        CustomerVisit visit = customerService.logVisit(customer.getCustomerId(), UUID.randomUUID(), "T3", "Alfredo Pasta x 1", BigDecimal.valueOf(262.50));
        assertNotNull(visit.getId());

        CustomerFeedbackRequest feedbackReq = CustomerFeedbackRequest.builder()
                .visitId(visit.getId())
                .rating(5)
                .comment("Excellent pasta and quick service!")
                .build();

        CustomerVisit ratedVisit = customerService.submitFeedback(feedbackReq);
        assertEquals(5, ratedVisit.getRating());
        assertEquals("Excellent pasta and quick service!", ratedVisit.getFeedbackComment());
    }

    @Test
    public void testVipTaggingAndSegmentation() {
        Customer customer = Customer.builder()
                .phone("9887766554")
                .name("VIP Person")
                .totalVisits(6)
                .totalSpend(BigDecimal.valueOf(3000.00))
                .lastVisitAt(LocalDateTime.now().minusDays(5))
                .build();
        customer = customerRepository.save(customer);

        CustomerResponse tagged = customerService.toggleVipTag(customer.getCustomerId(), true);
        assertTrue(tagged.getIsVip());

        String segment = customerService.getCustomerSegment(customer);
        assertEquals("HIGH_VALUE", segment);

        // Test Lapsed customer
        Customer lapsed = Customer.builder()
                .phone("9776655443")
                .name("Old Customer")
                .totalVisits(2)
                .totalSpend(BigDecimal.valueOf(500.00))
                .lastVisitAt(LocalDateTime.now().minusDays(40))
                .build();
        lapsed = customerRepository.save(lapsed);
        assertEquals("LAPSED", customerService.getCustomerSegment(lapsed));
    }

    @Test
    public void testTargetedAndBirthdayCampaigns() {
        Customer bdayCustomer = Customer.builder()
                .phone("9554433221")
                .name("Birthday Girl")
                .birthday(LocalDate.now().plusDays(3))
                .totalSpend(BigDecimal.ZERO)
                .build();
        customerRepository.save(bdayCustomer);

        assertDoesNotThrow(() -> customerService.sendTargetedCampaign("HIGH_VALUE", "Special 20% off for our top guests!"));
        assertDoesNotThrow(() -> customerService.runBirthdayCampaign());
    }

    @Test
    public void testCustomerAnalyticsResponse() {
        Customer customer = Customer.builder()
                .phone("9443322110")
                .name("Analytics Customer")
                .totalVisits(4)
                .totalSpend(BigDecimal.valueOf(1000.00))
                .pointsEarned(100)
                .pointsRedeemed(50)
                .build();
        customer = customerRepository.save(customer);

        CustomerAnalyticsResponse analytics = customerService.getCustomerAnalytics(customer.getCustomerId());
        assertEquals(BigDecimal.valueOf(250.00).setScale(2), analytics.getAverageOrderValue().setScale(2));
        assertEquals(50.0, analytics.getLoyaltyRedemptionRate());
    }
}
