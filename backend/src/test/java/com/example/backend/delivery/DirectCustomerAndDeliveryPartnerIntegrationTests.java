package com.example.backend.delivery;

import com.example.backend.chain.entity.Outlet;
import com.example.backend.chain.repository.OutletRepository;
import com.example.backend.customer.controller.CustomerAppController;
import com.example.backend.customer.dto.CustomerOrderTrackingResponse;
import com.example.backend.customer.dto.DirectOrderRequest;
import com.example.backend.delivery.controller.DeliveryManagementController;
import com.example.backend.delivery.controller.DeliveryPartnerController;
import com.example.backend.delivery.dto.*;
import com.example.backend.delivery.entity.AssignmentStatus;
import com.example.backend.delivery.entity.DeliveryPartnerStatus;
import com.example.backend.menu.entity.Category;
import com.example.backend.menu.entity.MenuItem;
import com.example.backend.menu.repository.CategoryRepository;
import com.example.backend.menu.repository.MenuItemRepository;
import com.example.backend.order.dto.OrderRequest;
import com.example.backend.order.entity.OrderStatus;
import com.example.backend.order.entity.OrderType;
import com.example.backend.order.service.KdsService;
import com.example.backend.order.entity.OrderItemStatus;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.ResponseEntity;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import org.springframework.security.test.context.support.WithMockUser;

import java.math.BigDecimal;
import java.util.Collections;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
@Transactional
@WithMockUser(username = "admin", roles = {"ADMIN", "MANAGER", "DELIVERY_PARTNER"})
public class DirectCustomerAndDeliveryPartnerIntegrationTests {

    @Autowired
    private DeliveryManagementController deliveryManagementController;

    @Autowired
    private DeliveryPartnerController deliveryPartnerController;

    @Autowired
    private CustomerAppController customerAppController;

    @Autowired
    private OutletRepository outletRepository;

    @Autowired
    private CategoryRepository categoryRepository;

    @Autowired
    private MenuItemRepository menuItemRepository;

    @Autowired
    private KdsService kdsService;

    @Autowired
    private com.example.backend.bill.service.BillService billService;

    @Autowired
    private com.example.backend.order.repository.OrderItemRepository orderItemRepository;

    private UUID outletId;
    private MenuItem testMenuItem;

    @BeforeEach
    public void setUp() {
        Outlet outlet = Outlet.builder()
                .name("Downtown Delivery Hub")
                .city("Downtown")
                .address("100 Main St")
                .build();
        outlet = outletRepository.save(outlet);
        this.outletId = outlet.getOutletId();

        Category mainCourse = Category.builder()
                .name("Main Course Delivery " + UUID.randomUUID())
                .build();
        mainCourse = categoryRepository.save(mainCourse);

        testMenuItem = MenuItem.builder()
                .name("Deluxe Burger")
                .category(mainCourse)
                .price(BigDecimal.valueOf(250.00))
                .foodType("VEG")
                .gstRate(BigDecimal.valueOf(5.0))
                .isAvailable(true)
                .build();
        testMenuItem = menuItemRepository.save(testMenuItem);
    }

    @Test
    public void testCompleteCustomerOrderAndDeliveryPartnerLifecycle() {
        // 1. Register Delivery Partner
        DeliveryPartnerRequest partnerReq = new DeliveryPartnerRequest();
        partnerReq.setName("Speedy Rider");
        String partnerPhone = "98" + (System.currentTimeMillis() % 100000000);
        partnerReq.setPhone(partnerPhone);
        partnerReq.setPinCode("4321");
        partnerReq.setVehicleNumber("KA-01-AB-1234");
        partnerReq.setVehicleType("BIKE");
        partnerReq.setOutletId(outletId);

        ResponseEntity<DeliveryPartnerResponse> regRes = deliveryManagementController.registerPartner(partnerReq);
        assertNotNull(regRes.getBody());
        UUID partnerId = regRes.getBody().getPartnerId();
        assertEquals("Speedy Rider", regRes.getBody().getName());

        // 2. Delivery Partner PIN Login
        DeliveryPinLoginRequest loginReq = new DeliveryPinLoginRequest();
        loginReq.setPhone(partnerPhone);
        loginReq.setPinCode("4321");
        ResponseEntity<DeliveryPinLoginResponse> loginRes = deliveryPartnerController.loginWithPin(loginReq);
        assertNotNull(loginRes.getBody());
        assertNotNull(loginRes.getBody().getToken());

        // 3. Driver goes ONLINE & pings GPS coordinates
        deliveryPartnerController.updateStatus(partnerId, DeliveryPartnerStatus.ONLINE);
        LocationUpdateRequest locReq = new LocationUpdateRequest();
        locReq.setLatitude(12.9716);
        locReq.setLongitude(77.5946);
        deliveryPartnerController.updateLocation(partnerId, locReq);

        // 4. Customer places Direct Delivery Order via Customer App
        DirectOrderRequest directOrderReq = new DirectOrderRequest();
        directOrderReq.setOutletId(outletId);
        directOrderReq.setCustomerName("John Customer");
        directOrderReq.setCustomerPhone("9112233445");
        directOrderReq.setOrderType(OrderType.DELIVERY);
        directOrderReq.setDeliveryAddress("Flat 402, Sunshine Apartments, Indiranagar");
        directOrderReq.setDeliveryNotes("Ring doorbell twice");
        directOrderReq.setPaymentMethod("COD");

        DirectOrderRequest.ItemRequest itemReq = new DirectOrderRequest.ItemRequest();
        itemReq.setMenuItemId(testMenuItem.getItemId());
        itemReq.setQuantity(2);
        directOrderReq.setItems(Collections.singletonList(itemReq));

        ResponseEntity<CustomerOrderTrackingResponse> orderRes = customerAppController.placeDirectOrder(directOrderReq);
        assertNotNull(orderRes.getBody());
        UUID orderId = orderRes.getBody().getOrderId();
        assertEquals(OrderStatus.NEW, orderRes.getBody().getStatus());

        // 5. Dispatcher auto-assigns order to online Delivery Partner
        ResponseEntity<DeliveryAssignmentResponse> assignRes = deliveryManagementController.autoAssignOrder(orderId);
        assertNotNull(assignRes.getBody());
        UUID assignmentId = assignRes.getBody().getAssignmentId();
        String otpCode = assignRes.getBody().getOtpCode();
        assertNotNull(otpCode);

        // 6. Delivery Partner accepts assignment
        ResponseEntity<DeliveryAssignmentResponse> acceptRes = deliveryPartnerController.acceptAssignment(assignmentId, partnerId);
        assertEquals(AssignmentStatus.ACCEPTED, acceptRes.getBody().getStatus());

        // 7. Delivery Partner picks up order from kitchen
        ResponseEntity<DeliveryAssignmentResponse> pickupRes = deliveryPartnerController.pickupOrder(assignmentId, partnerId);
        assertEquals(AssignmentStatus.PICKED_UP, pickupRes.getBody().getStatus());

        // 8. Customer tracks order live status & delivery driver coordinates
        ResponseEntity<CustomerOrderTrackingResponse> trackRes = customerAppController.trackOrder(orderId);
        assertEquals(OrderStatus.OUT_FOR_DELIVERY, trackRes.getBody().getStatus());
        assertEquals("Speedy Rider", trackRes.getBody().getPartnerName());
        assertEquals(Double.valueOf(12.9716), trackRes.getBody().getPartnerCurrentLat());

        // 9. Delivery Partner completes drop-off with OTP verification
        CompleteDeliveryRequest completeReq = new CompleteDeliveryRequest();
        completeReq.setOtpCode(otpCode);
        completeReq.setNotes("Delivered to customer at door");
        ResponseEntity<DeliveryAssignmentResponse> completeRes = deliveryPartnerController.completeDelivery(assignmentId, partnerId, completeReq);
        assertEquals(AssignmentStatus.DELIVERED, completeRes.getBody().getStatus());

        // 10. Final check customer order status
        ResponseEntity<CustomerOrderTrackingResponse> finalTrack = customerAppController.trackOrder(orderId);
        assertEquals(OrderStatus.DELIVERED, finalTrack.getBody().getStatus());
    }

    @Test
    public void testKitchenServedAutoAssignsDeliveryPartnerAndDelivers() {
        // 1. Register Delivery Partner
        DeliveryPartnerRequest partnerReq = new DeliveryPartnerRequest();
        partnerReq.setName("Alex Kitchen Rider");
        String partnerPhone = "99" + (System.currentTimeMillis() % 100000000);
        partnerReq.setPhone(partnerPhone);
        partnerReq.setPinCode("1234");
        partnerReq.setVehicleNumber("KA-05-CD-9999");
        partnerReq.setVehicleType("BIKE");
        partnerReq.setOutletId(outletId);

        ResponseEntity<DeliveryPartnerResponse> regRes = deliveryManagementController.registerPartner(partnerReq);
        assertNotNull(regRes.getBody());
        UUID partnerId = regRes.getBody().getPartnerId();

        // Put driver online in outlet
        deliveryPartnerController.updateStatus(partnerId, DeliveryPartnerStatus.ONLINE);

        // 2. Place Customer Online Delivery Order
        DirectOrderRequest directOrderReq = new DirectOrderRequest();
        directOrderReq.setOutletId(outletId);
        directOrderReq.setCustomerName("Alice Customer");
        directOrderReq.setCustomerPhone("9887766554");
        directOrderReq.setOrderType(OrderType.DELIVERY);
        directOrderReq.setDeliveryAddress("Villa 12, Palm Meadows");
        directOrderReq.setPaymentMethod("COD");

        DirectOrderRequest.ItemRequest itemReq = new DirectOrderRequest.ItemRequest();
        itemReq.setMenuItemId(testMenuItem.getItemId());
        itemReq.setQuantity(1);
        directOrderReq.setItems(Collections.singletonList(itemReq));

        ResponseEntity<CustomerOrderTrackingResponse> orderRes = customerAppController.placeDirectOrder(directOrderReq);
        assertNotNull(orderRes.getBody());
        UUID orderId = orderRes.getBody().getOrderId();
        assertEquals(OrderStatus.NEW, orderRes.getBody().getStatus());

        // 3. Kitchen marks order as SERVED -> automatically triggers delivery partner assignment!
        com.example.backend.order.entity.Order servedOrder = kdsService.markOrderServed(orderId);
        assertNotNull(servedOrder);
        assertEquals(OrderStatus.ASSIGNED, servedOrder.getStatus());
        assertNotNull(servedOrder.getDeliveryPartnerId());
        assertNotNull(servedOrder.getDeliveryOtp());

        // 4. Partner sees the assignment in their deliveries
        UUID assignedPartnerId = servedOrder.getDeliveryPartnerId();
        assertNotNull(assignedPartnerId);
        ResponseEntity<List<DeliveryAssignmentResponse>> partnerDeliveries = deliveryPartnerController.getMyDeliveries(assignedPartnerId);
        assertNotNull(partnerDeliveries.getBody());
        assertFalse(partnerDeliveries.getBody().isEmpty());
        DeliveryAssignmentResponse assignment = partnerDeliveries.getBody().get(0);
        UUID assignmentId = assignment.getAssignmentId();

        // 5. Partner accepts and picks up order
        deliveryPartnerController.acceptAssignment(assignmentId, assignedPartnerId);
        deliveryPartnerController.pickupOrder(assignmentId, assignedPartnerId);

        // Verify tracking is OUT_FOR_DELIVERY
        ResponseEntity<CustomerOrderTrackingResponse> trackRes = customerAppController.trackOrder(orderId);
        assertEquals(OrderStatus.OUT_FOR_DELIVERY, trackRes.getBody().getStatus());
        assertNotNull(trackRes.getBody().getPartnerName());

        // 6. Partner completes delivery with OTP
        CompleteDeliveryRequest completeReq = new CompleteDeliveryRequest();
        completeReq.setOtpCode(servedOrder.getDeliveryOtp());
        completeReq.setNotes("Delivered at doorstep");
        ResponseEntity<DeliveryAssignmentResponse> deliveredRes = deliveryPartnerController.completeDelivery(assignmentId, assignedPartnerId, completeReq);
        assertEquals(AssignmentStatus.DELIVERED, deliveredRes.getBody().getStatus());

        // Verify final tracking is DELIVERED
        ResponseEntity<CustomerOrderTrackingResponse> finalTrack = customerAppController.trackOrder(orderId);
        assertEquals(OrderStatus.DELIVERED, finalTrack.getBody().getStatus());
    }

    @Test
    public void testOrderAssignedToKitchenOnlyAfterPaymentSuccess() {
        // 1. Customer places an online prepaid order (RAZORPAY)
        DirectOrderRequest directOrderReq = new DirectOrderRequest();
        directOrderReq.setOutletId(outletId);
        directOrderReq.setCustomerName("Bob Online");
        directOrderReq.setCustomerPhone("9776655443");
        directOrderReq.setOrderType(OrderType.DELIVERY);
        directOrderReq.setDeliveryAddress("Apt 101, Lakeview Residency");
        directOrderReq.setPaymentMethod("RAZORPAY");

        DirectOrderRequest.ItemRequest itemReq = new DirectOrderRequest.ItemRequest();
        itemReq.setMenuItemId(testMenuItem.getItemId());
        itemReq.setQuantity(2);
        directOrderReq.setItems(Collections.singletonList(itemReq));

        ResponseEntity<CustomerOrderTrackingResponse> orderRes = customerAppController.placeDirectOrder(directOrderReq);
        assertNotNull(orderRes.getBody());
        UUID orderId = orderRes.getBody().getOrderId();
        assertEquals(OrderStatus.NEW, orderRes.getBody().getStatus());
        assertEquals("PENDING", orderRes.getBody().getPaymentStatus());

        // Items must be in PENDING status before payment
        List<com.example.backend.order.entity.OrderItem> itemsBefore = orderItemRepository.findByOrderId(orderId);
        assertFalse(itemsBefore.isEmpty());
        assertEquals(OrderItemStatus.PENDING, itemsBefore.get(0).getStatus());

        // Kitchen Display (KDS) MUST NOT show unpaid orders!
        List<com.example.backend.order.dto.KdsItemResponse> kdsOrdersBefore = kdsService.getAllKdsOrders();
        boolean appearsBeforePayment = kdsOrdersBefore.stream().anyMatch(k -> k.getOrderId().equals(orderId));
        assertFalse(appearsBeforePayment, "Unpaid online order must NOT appear in KDS before payment");

        // 2. Customer completes Razorpay payment successfully
        String paymentJson = "{\"razorpayPaymentId\":\"pay_test_online_999\",\"status\":\"PAID\"}";
        com.example.backend.bill.entity.Bill settledBill = billService.settleBill(orderId, paymentJson, "9776655443");
        assertNotNull(settledBill);
        assertTrue(settledBill.isSettled());

        // 3. Verify order is now ASSIGNED to kitchen
        ResponseEntity<CustomerOrderTrackingResponse> trackRes = customerAppController.trackOrder(orderId);
        assertNotNull(trackRes.getBody());
        assertEquals(OrderStatus.PREPARING, trackRes.getBody().getStatus(), "Order status must transition to PREPARING upon payment");
        assertEquals("PAID", trackRes.getBody().getPaymentStatus());

        // Verify order items transitioned to PREPARING
        List<com.example.backend.order.entity.OrderItem> itemsAfter = orderItemRepository.findByOrderId(orderId);
        assertFalse(itemsAfter.isEmpty());
        assertEquals(OrderItemStatus.PREPARING, itemsAfter.get(0).getStatus(), "Order items must transition to PREPARING upon payment");

        // Verify order NOW appears in KDS for kitchen staff to cook
        List<com.example.backend.order.dto.KdsItemResponse> kdsOrdersAfter = kdsService.getAllKdsOrders();
        boolean appearsAfterPayment = kdsOrdersAfter.stream().anyMatch(k -> k.getOrderId().equals(orderId));
        assertTrue(appearsAfterPayment, "Paid order must appear in KDS once payment is successful");

        // 4. Kitchen marks order READY and then SERVED
        com.example.backend.order.entity.Order readyOrder = kdsService.markOrderReady(orderId);
        assertEquals(OrderStatus.READY, readyOrder.getStatus());

        com.example.backend.order.entity.Order servedOrder = kdsService.markOrderServed(orderId);
        assertNotNull(servedOrder);
        // Delivery order served by kitchen moves to ASSIGNED (delivery partner auto-assigned)
        assertEquals(OrderStatus.ASSIGNED, servedOrder.getStatus());
        assertNotNull(servedOrder.getDeliveryPartnerId());
    }
}