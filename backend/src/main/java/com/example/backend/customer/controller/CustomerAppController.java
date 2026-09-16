package com.example.backend.customer.controller;

import com.example.backend.bill.entity.Bill;
import com.example.backend.bill.repository.BillRepository;
import com.example.backend.bill.service.BillService;
import com.example.backend.customer.dto.*;
import com.example.backend.customer.entity.CustomerVisit;
import com.example.backend.customer.service.CartService;
import com.example.backend.customer.service.CustomerAddressService;
import com.example.backend.customer.service.CustomerService;
import com.example.backend.customer.service.WishlistService;
import com.example.backend.delivery.entity.DeliveryPartner;
import com.example.backend.delivery.repository.DeliveryPartnerRepository;
import com.example.backend.menu.entity.Category;
import com.example.backend.menu.entity.MenuItem;
import com.example.backend.menu.repository.CategoryRepository;
import com.example.backend.menu.repository.MenuItemRepository;
import com.example.backend.order.entity.*;
import com.example.backend.order.repository.OrderItemRepository;
import com.example.backend.order.repository.OrderRepository;
import com.example.backend.order.service.OrderService;
import com.example.backend.reservation.entity.Reservation;
import com.example.backend.reservation.service.ReservationService;
import com.example.backend.table.entity.RestaurantTable;
import com.example.backend.table.service.TableService;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/customer-app")
public class CustomerAppController {

    private final MenuItemRepository menuItemRepository;
    private final CategoryRepository categoryRepository;
    private final OrderRepository orderRepository;
    private final OrderItemRepository orderItemRepository;
    private final OrderService orderService;
    private final DeliveryPartnerRepository deliveryPartnerRepository;
    private final CustomerService customerService;
    private final CustomerAddressService customerAddressService;
    private final ReservationService reservationService;
    private final CartService cartService;
    private final WishlistService wishlistService;
    private final TableService tableService;
    private final BillService billService;
    private final BillRepository billRepository;
    private final SimpMessagingTemplate messagingTemplate;

    public CustomerAppController(MenuItemRepository menuItemRepository,
                                 CategoryRepository categoryRepository,
                                 OrderRepository orderRepository,
                                 OrderItemRepository orderItemRepository,
                                 OrderService orderService,
                                 DeliveryPartnerRepository deliveryPartnerRepository,
                                 CustomerService customerService,
                                 CustomerAddressService customerAddressService,
                                 ReservationService reservationService,
                                 CartService cartService,
                                 WishlistService wishlistService,
                                 TableService tableService,
                                 BillService billService,
                                 BillRepository billRepository,
                                 SimpMessagingTemplate messagingTemplate) {
        this.menuItemRepository = menuItemRepository;
        this.categoryRepository = categoryRepository;
        this.orderRepository = orderRepository;
        this.orderItemRepository = orderItemRepository;
        this.orderService = orderService;
        this.deliveryPartnerRepository = deliveryPartnerRepository;
        this.customerService = customerService;
        this.customerAddressService = customerAddressService;
        this.reservationService = reservationService;
        this.cartService = cartService;
        this.wishlistService = wishlistService;
        this.tableService = tableService;
        this.billService = billService;
        this.billRepository = billRepository;
        this.messagingTemplate = messagingTemplate;
    }

    // ==========================================
    // 1. AUTHENTICATION & SIGNUP
    // ==========================================

    @PostMapping("/signup")
    public ResponseEntity<CustomerResponse> signUpCustomer(@Valid @RequestBody CustomerRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(customerService.createCustomer(request));
    }



    // ==========================================
    // 2. PROFILE & CRM
    // ==========================================

    @GetMapping("/profile")
    public ResponseEntity<CustomerResponse> getCustomerProfile(
            @RequestParam(required = false) String phone,
            @RequestParam(required = false) String customerId) {
        if (phone != null && !phone.isBlank()) {
            return ResponseEntity.ok(customerService.getAllCustomers().stream()
                    .filter(c -> phone.equalsIgnoreCase(c.getPhone()))
                    .findFirst()
                    .orElseGet(() -> CustomerResponse.builder()
                            .phone(phone)
                            .name("Gourmet Customer")
                            .email("customer@gourmet.com")
                            .loyaltyPoints(120)
                            .build()));
        } else if (customerId != null && !customerId.isBlank()) {
            try {
                UUID id = UUID.fromString(customerId);
                return ResponseEntity.ok(customerService.getCustomerById(id));
            } catch (Exception ignored) {}
        }
        List<CustomerResponse> customers = customerService.getAllCustomers();
        if (!customers.isEmpty()) {
            return ResponseEntity.ok(customers.get(0));
        }
        return ResponseEntity.ok(CustomerResponse.builder()
                .phone("+91 9876543210")
                .name("Gourmet Customer")
                .email("customer@gourmet.com")
                .loyaltyPoints(120)
                .build());
    }

    @PostMapping("/profile/update")
    public ResponseEntity<CustomerResponse> updateCustomerProfile(@RequestBody UpdateProfileRequest request) {
        String phone = request.getPhone();
        CustomerResponse existing = null;
        if (phone != null && !phone.isBlank()) {
            existing = customerService.getAllCustomers().stream()
                    .filter(c -> phone.equalsIgnoreCase(c.getPhone()))
                    .findFirst().orElse(null);
        }

        if (existing != null) {
            CustomerRequest updateReq = CustomerRequest.builder()
                    .name(request.getName() != null ? request.getName() : existing.getName())
                    .phone(existing.getPhone())
                    .email(request.getEmail() != null ? request.getEmail() : existing.getEmail())
                    .birthday(request.getBirthday() != null ? request.getBirthday() : existing.getBirthday())
                    .build();
            return ResponseEntity.ok(customerService.updateCustomer(existing.getCustomerId(), updateReq));
        }

        CustomerRequest newReq = CustomerRequest.builder()
                .name(request.getName() != null ? request.getName() : "Gourmet Customer")
                .phone(request.getPhone() != null ? request.getPhone() : "+91 9876543210")
                .email(request.getEmail())
                .birthday(request.getBirthday())
                .build();
        return ResponseEntity.ok(customerService.createCustomer(newReq));
    }

    // ==========================================
    // 2.1 CUSTOMER ADDRESS MANAGEMENT
    // ==========================================

    private UUID resolveCustomerId(String phone, String customerIdStr) {
        if (customerIdStr != null && !customerIdStr.isBlank()) {
            try {
                return UUID.fromString(customerIdStr);
            } catch (Exception ignored) {}
        }
        if (phone != null && !phone.isBlank()) {
            return customerService.getAllCustomers().stream()
                    .filter(c -> phone.equalsIgnoreCase(c.getPhone()))
                    .map(CustomerResponse::getCustomerId)
                    .findFirst()
                    .orElseGet(() -> {
                        CustomerResponse newCustomer = customerService.createCustomer(CustomerRequest.builder()
                                .phone(phone)
                                .name("Gourmet Customer")
                                .build());
                        return newCustomer.getCustomerId();
                    });
        }
        CustomerResponse defaultCust = customerService.getAllCustomers().stream()
                .findFirst()
                .orElseGet(() -> customerService.createCustomer(CustomerRequest.builder()
                        .phone("+91 9876543210")
                        .name("Gourmet Customer")
                        .build()));
        return defaultCust.getCustomerId();
    }

    @GetMapping("/addresses")
    public ResponseEntity<List<CustomerAddressResponse>> getCustomerAddresses(
            @RequestParam(required = false) String phone,
            @RequestParam(required = false) String customerId) {
        UUID id = resolveCustomerId(phone, customerId);
        return ResponseEntity.ok(customerAddressService.getAddressesForCustomer(id));
    }

    @GetMapping("/addresses/{addressId}")
    public ResponseEntity<CustomerAddressResponse> getAddressById(@PathVariable UUID addressId) {
        return ResponseEntity.ok(customerAddressService.getAddressById(addressId));
    }

    @PostMapping("/addresses")
    public ResponseEntity<CustomerAddressResponse> addCustomerAddress(
            @RequestParam(required = false) String phone,
            @RequestParam(required = false) String customerId,
            @Valid @RequestBody CustomerAddressRequest request) {
        UUID id = resolveCustomerId(phone, customerId);
        return ResponseEntity.status(HttpStatus.CREATED).body(customerAddressService.addAddress(id, request));
    }

    @PutMapping("/addresses/{addressId}")
    public ResponseEntity<CustomerAddressResponse> updateCustomerAddress(
            @PathVariable UUID addressId,
            @RequestBody CustomerAddressRequest request) {
        return ResponseEntity.ok(customerAddressService.updateAddress(addressId, request));
    }

    @DeleteMapping("/addresses/{addressId}")
    public ResponseEntity<Map<String, Object>> deleteCustomerAddress(
            @PathVariable UUID addressId,
            @RequestParam(required = false) String phone,
            @RequestParam(required = false) String customerId) {
        UUID id = resolveCustomerId(phone, customerId);
        customerAddressService.deleteAddress(id, addressId);
        return ResponseEntity.ok(Map.of("message", "Address deleted successfully", "addressId", addressId));
    }

    @PatchMapping("/addresses/{addressId}/default")
    public ResponseEntity<CustomerAddressResponse> setDefaultCustomerAddress(
            @PathVariable UUID addressId,
            @RequestParam(required = false) String phone,
            @RequestParam(required = false) String customerId) {
        UUID id = resolveCustomerId(phone, customerId);
        return ResponseEntity.ok(customerAddressService.setDefaultAddress(id, addressId));
    }

    // ==========================================
    // 3. MENU & CATEGORIES & MODIFIERS
    // ==========================================

    @GetMapping("/menu")
    public ResponseEntity<List<MenuItem>> getActiveMenu() {
        ensureDefaultMenuSeeded();
        List<MenuItem> activeItems = menuItemRepository.findAll().stream()
                .filter(MenuItem::isAvailable)
                .collect(Collectors.toList());
        return ResponseEntity.ok(activeItems);
    }

    @GetMapping("/categories")
    public ResponseEntity<List<Category>> getCategories() {
        ensureDefaultMenuSeeded();
        return ResponseEntity.ok(categoryRepository.findAll());
    }

    @GetMapping("/menu/category/{categoryId}")
    public ResponseEntity<List<MenuItem>> getMenuItemsByCategory(@PathVariable UUID categoryId) {
        ensureDefaultMenuSeeded();
        List<MenuItem> items = menuItemRepository.findByCategoryCategoryId(categoryId).stream()
                .filter(MenuItem::isAvailable)
                .collect(Collectors.toList());
        return ResponseEntity.ok(items);
    }

    @GetMapping("/menu/{itemId}/modifiers")
    public ResponseEntity<List<Map<String, Object>>> getItemModifiers(@PathVariable UUID itemId) {
        List<Map<String, Object>> modifierGroups = new ArrayList<>();

        Map<String, Object> sizeGroup = new HashMap<>();
        sizeGroup.put("id", "mod_group_size");
        sizeGroup.put("title", "Portion Size");
        sizeGroup.put("isRequired", false);
        sizeGroup.put("allowsMultiple", false);
        sizeGroup.put("options", List.of(
                Map.of("id", "opt_regular", "name", "Regular", "extraPrice", 0),
                Map.of("id", "opt_large", "name", "Large Portion (+₹80)", "extraPrice", 80)
        ));

        Map<String, Object> addonGroup = new HashMap<>();
        addonGroup.put("id", "mod_group_addons");
        addonGroup.put("title", "Add-ons & Sides");
        addonGroup.put("isRequired", false);
        addonGroup.put("allowsMultiple", true);
        addonGroup.put("options", List.of(
                Map.of("id", "opt_cheese", "name", "Extra Gourmet Cheese", "extraPrice", 45),
                Map.of("id", "opt_dip", "name", "House Special Dip", "extraPrice", 30)
        ));

        modifierGroups.add(sizeGroup);
        modifierGroups.add(addonGroup);
        return ResponseEntity.ok(modifierGroups);
    }

    // ==========================================
    // 4. CART & WISHLIST ENDPOINTS
    // ==========================================

    @GetMapping("/cart")
    public ResponseEntity<CartResponse> getCart(@RequestParam String phone) {
        return ResponseEntity.ok(cartService.getCart(phone));
    }

    @PostMapping("/cart/item")
    public ResponseEntity<CartResponse> updateCartItem(@RequestBody CartItemRequest request) {
        return ResponseEntity.ok(cartService.updateCartItem(request));
    }

    @DeleteMapping("/cart/item/{cartItemId}")
    public ResponseEntity<CartResponse> removeCartItem(@PathVariable String cartItemId, @RequestParam(required = false) String phone) {
        if (phone == null || phone.isBlank()) phone = "+91 9876543210";
        return ResponseEntity.ok(cartService.removeCartItem(phone, cartItemId));
    }

    @PostMapping("/cart/clear")
    public ResponseEntity<CartResponse> clearCart(@RequestBody Map<String, String> body) {
        String phone = body.get("phone");
        if (phone == null || phone.isBlank()) phone = "+91 9876543210";
        return ResponseEntity.ok(cartService.clearCart(phone));
    }

    @PostMapping("/cart/apply-coupon")
    public ResponseEntity<Map<String, Object>> applyCoupon(@RequestBody CouponRequest request) {
        return ResponseEntity.ok(cartService.applyCoupon(request.getPhone(), request.getCouponCode()));
    }

    @GetMapping("/wishlist")
    public ResponseEntity<List<MenuItem>> getWishlist(@RequestParam String phone) {
        ensureDefaultMenuSeeded();
        return ResponseEntity.ok(wishlistService.getWishlist(phone));
    }

    @PostMapping("/wishlist/toggle")
    public ResponseEntity<Map<String, Object>> toggleWishlist(@RequestBody WishlistToggleRequest request) {
        UUID itemId = request.getMenuItemId() != null ? request.getMenuItemId() : request.getItemId();
        return ResponseEntity.ok(wishlistService.toggleWishlist(request.getPhone(), itemId));
    }

    // ==========================================
    // 5. ORDERS & TRACKING & HISTORY
    // ==========================================

    @PostMapping("/orders")
    @Transactional
    public ResponseEntity<CustomerOrderTrackingResponse> placeDirectOrder(@RequestBody DirectOrderRequest request) {
        OrderType type = request.getOrderType() != null ? request.getOrderType() : OrderType.DELIVERY;

        String deliveryAddress = request.getDeliveryAddress();
        Double deliveryLat = request.getDeliveryLat();
        Double deliveryLng = request.getDeliveryLng();

        if (request.getAddressId() != null) {
            try {
                CustomerAddressResponse savedAddr = customerAddressService.getAddressById(request.getAddressId());
                if (deliveryAddress == null || deliveryAddress.isBlank()) {
                    deliveryAddress = savedAddr.getFullAddress();
                }
                if (deliveryLat == null) {
                    deliveryLat = savedAddr.getLatitude();
                }
                if (deliveryLng == null) {
                    deliveryLng = savedAddr.getLongitude();
                }
            } catch (Exception ignored) {}
        }

        String payMethod = request.getPaymentMethod() != null ? request.getPaymentMethod().toUpperCase() : "COD";
        boolean isPrepaid = !"COD".equalsIgnoreCase(payMethod);

        Order order = Order.builder()
                .outletId(request.getOutletId())
                .orderType(type)
                .status(OrderStatus.NEW)
                .customerName(request.getCustomerName())
                .customerPhone(request.getCustomerPhone())
                .deliveryAddress(deliveryAddress)
                .deliveryNotes(request.getDeliveryNotes())
                .deliveryLat(deliveryLat)
                .deliveryLng(deliveryLng)
                .paymentMethod(payMethod)
                .paymentStatus("PENDING")
                .estimatedDeliveryTime(LocalDateTime.now().plusMinutes(35))
                .kotFiredAt(isPrepaid ? null : LocalDateTime.now())
                .isTraining(false)
                .build();

        Order savedOrder = orderRepository.save(order);

        List<CustomerOrderTrackingResponse.TrackedItem> trackedItems = new ArrayList<>();

        if (request.getItems() != null) {
            for (DirectOrderRequest.ItemRequest itemReq : request.getItems()) {
                MenuItem menuItem = menuItemRepository.findById(itemReq.getMenuItemId()).orElse(null);
                if (menuItem != null) {
                    OrderItem orderItem = OrderItem.builder()
                            .orderId(savedOrder.getOrderId())
                            .menuItemId(menuItem.getItemId())
                            .quantity(itemReq.getQuantity())
                            .unitPrice(menuItem.getPrice())
                            .modifiers(itemReq.getModifiers())
                            .status(isPrepaid ? OrderItemStatus.PENDING : OrderItemStatus.PREPARING)
                            .build();

                    orderItemRepository.save(orderItem);

                    trackedItems.add(CustomerOrderTrackingResponse.TrackedItem.builder()
                            .menuItemName(menuItem.getName())
                            .quantity(itemReq.getQuantity())
                            .price(menuItem.getPrice())
                            .build());
                }
            }
        }

        orderService.logTimelineEvent(savedOrder.getOrderId(), "DIRECT_APP_ORDER_PLACED",
                "Direct customer app order placed by " + request.getCustomerName() + " (" + request.getCustomerPhone() + ")"
                + (isPrepaid ? " - Awaiting online payment" : " - Cash on Delivery"), "CustomerApp");

        if (!isPrepaid) {
            orderService.logTimelineEvent(savedOrder.getOrderId(), "ASSIGNED_TO_KITCHEN",
                    "Cash on Delivery order assigned to kitchen for preparation.", "System");
        }

        try {
            billService.generateBill(savedOrder.getOrderId(), BigDecimal.ZERO, request.getCustomerPhone(), null, null);
            savedOrder.setStatus(OrderStatus.NEW);
            orderRepository.save(savedOrder);
        } catch (Exception ignored) {}

        if (!isPrepaid) {
            try {
                messagingTemplate.convertAndSend("/topic/orders", savedOrder);
                messagingTemplate.convertAndSend("/topic/alerts", (Object) Map.of(
                        "type", "NEW_ORDER",
                        "orderId", savedOrder.getOrderId(),
                        "message", "New COD order #" + savedOrder.getOrderId().toString().substring(0, 8) + " assigned to kitchen!"
                ));
            } catch (Exception ignored) {}
        }

        CustomerOrderTrackingResponse response = CustomerOrderTrackingResponse.builder()
                .orderId(savedOrder.getOrderId())
                .orderType(savedOrder.getOrderType())
                .status(savedOrder.getStatus())
                .customerName(savedOrder.getCustomerName())
                .customerPhone(savedOrder.getCustomerPhone())
                .deliveryAddress(savedOrder.getDeliveryAddress())
                .deliveryNotes(savedOrder.getDeliveryNotes())
                .paymentMethod(savedOrder.getPaymentMethod())
                .paymentStatus(savedOrder.getPaymentStatus())
                .estimatedDeliveryTime(savedOrder.getEstimatedDeliveryTime())
                .items(trackedItems)
                .build();

        return ResponseEntity.ok(response);
    }

    @GetMapping("/orders/{orderId}/track")
    public ResponseEntity<CustomerOrderTrackingResponse> trackOrder(@PathVariable UUID orderId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found"));

        List<OrderItem> items = orderItemRepository.findByOrderId(orderId);
        List<CustomerOrderTrackingResponse.TrackedItem> trackedItems = new ArrayList<>();
        for (OrderItem item : items) {
            MenuItem menuItem = menuItemRepository.findById(item.getMenuItemId()).orElse(null);
            if (menuItem != null) {
                trackedItems.add(CustomerOrderTrackingResponse.TrackedItem.builder()
                        .menuItemName(menuItem.getName())
                        .quantity(item.getQuantity())
                        .price(item.getUnitPrice())
                        .build());
            }
        }

        DeliveryPartner partner = null;
        if (order.getDeliveryPartnerId() != null) {
            partner = deliveryPartnerRepository.findById(order.getDeliveryPartnerId()).orElse(null);
        }

        CustomerOrderTrackingResponse response = CustomerOrderTrackingResponse.builder()
                .orderId(order.getOrderId())
                .orderType(order.getOrderType())
                .status(order.getStatus())
                .customerName(order.getCustomerName())
                .customerPhone(order.getCustomerPhone())
                .deliveryAddress(order.getDeliveryAddress())
                .deliveryNotes(order.getDeliveryNotes())
                .deliveryOtp(order.getDeliveryOtp())
                .paymentMethod(order.getPaymentMethod())
                .paymentStatus(order.getPaymentStatus())
                .estimatedDeliveryTime(order.getEstimatedDeliveryTime())
                .partnerId(partner != null ? partner.getPartnerId() : null)
                .partnerName(partner != null ? partner.getName() : null)
                .partnerPhone(partner != null ? partner.getPhone() : null)
                .partnerVehicleNumber(partner != null ? partner.getVehicleNumber() : null)
                .partnerCurrentLat(partner != null ? partner.getCurrentLat() : null)
                .partnerCurrentLng(partner != null ? partner.getCurrentLng() : null)
                .partnerLastLocationUpdate(partner != null ? partner.getLastLocationUpdate() : null)
                .items(trackedItems)
                .build();

        return ResponseEntity.ok(response);
    }

    @GetMapping("/orders/history")
    public ResponseEntity<List<CustomerOrderHistoryResponse>> getCustomerOrderHistory(@RequestParam String phone) {
        List<Order> orders = orderRepository.findByCustomerPhone(phone);
        List<CustomerOrderHistoryResponse> responses = new ArrayList<>();

        for (Order order : orders) {
            List<OrderItem> orderItems = orderItemRepository.findByOrderId(order.getOrderId());
            List<CustomerOrderTrackingResponse.TrackedItem> trackedItems = new ArrayList<>();
            BigDecimal calculatedSubtotal = BigDecimal.ZERO;

            for (OrderItem item : orderItems) {
                MenuItem menuItem = menuItemRepository.findById(item.getMenuItemId()).orElse(null);
                String itemName = menuItem != null ? menuItem.getName() : "Delicious Dish";
                BigDecimal itemPrice = item.getUnitPrice() != null ? item.getUnitPrice() : (menuItem != null ? menuItem.getPrice() : BigDecimal.ZERO);
                BigDecimal lineTotal = itemPrice.multiply(BigDecimal.valueOf(item.getQuantity()));
                calculatedSubtotal = calculatedSubtotal.add(lineTotal);

                trackedItems.add(CustomerOrderTrackingResponse.TrackedItem.builder()
                        .menuItemName(itemName)
                        .quantity(item.getQuantity())
                        .price(itemPrice)
                        .build());
            }

            Optional<Bill> billOpt = billRepository.findByOrderId(order.getOrderId());
            BigDecimal subtotal = billOpt.map(Bill::getSubtotal).orElse(calculatedSubtotal);
            BigDecimal gstAmount = billOpt.map(b -> b.getCgst().add(b.getSgst()))
                    .orElse(calculatedSubtotal.multiply(BigDecimal.valueOf(0.05)).setScale(2, RoundingMode.HALF_UP));
            BigDecimal discount = billOpt.map(Bill::getDiscount).orElse(BigDecimal.ZERO);
            BigDecimal deliveryFee = order.getOrderType() == OrderType.DELIVERY ? BigDecimal.valueOf(40.0) : BigDecimal.ZERO;
            BigDecimal grandTotal = billOpt.map(Bill::getTotal)
                    .orElse(calculatedSubtotal.add(gstAmount).add(deliveryFee).subtract(discount));

            LocalDateTime createdAt = order.getSeatedAt() != null
                    ? order.getSeatedAt()
                    : (order.getEstimatedDeliveryTime() != null ? order.getEstimatedDeliveryTime().minusMinutes(35) : LocalDateTime.now());

            String tableNum = null;
            if (order.getTableId() != null) {
                try {
                    tableNum = tableService.getTableById(order.getTableId()).getTableNumber();
                } catch (Exception ignored) {}
            }

            responses.add(CustomerOrderHistoryResponse.builder()
                    .orderId(order.getOrderId())
                    .outletId(order.getOutletId())
                    .tableId(order.getTableId())
                    .tableNumber(tableNum)
                    .orderType(order.getOrderType())
                    .status(order.getStatus())
                    .orderStatus(order.getStatus() != null ? order.getStatus().name() : "PLACED")
                    .customerName(order.getCustomerName())
                    .customerPhone(order.getCustomerPhone())
                    .deliveryAddress(order.getDeliveryAddress())
                    .deliveryNotes(order.getDeliveryNotes())
                    .deliveryOtp(order.getDeliveryOtp())
                    .paymentMethod(order.getPaymentMethod())
                    .paymentStatus(order.getPaymentStatus())
                    .estimatedDeliveryTime(order.getEstimatedDeliveryTime())
                    .createdAt(createdAt)
                    .subtotal(subtotal)
                    .gstAmount(gstAmount)
                    .deliveryFee(deliveryFee)
                    .discount(discount)
                    .grandTotal(grandTotal)
                    .totalAmount(grandTotal)
                    .items(trackedItems)
                    .build());
        }

        responses.sort((a, b) -> {
            if (a.getCreatedAt() == null || b.getCreatedAt() == null) return 0;
            return b.getCreatedAt().compareTo(a.getCreatedAt());
        });

        return ResponseEntity.ok(responses);
    }

    // ==========================================
    // 6. RESERVATIONS & TABLES & BILL SETTLEMENT
    // ==========================================

    @PostMapping("/reservations")
    public ResponseEntity<Reservation> createOnlineReservation(@Valid @RequestBody Reservation reservation) {
        return ResponseEntity.status(HttpStatus.CREATED).body(reservationService.createOnlineReservation(reservation));
    }

    @GetMapping("/reservations/history")
    public ResponseEntity<List<Reservation>> getCustomerReservationHistory(@RequestParam String phone) {
        return ResponseEntity.ok(reservationService.getReservationsByPhone(phone));
    }

    @PostMapping("/reservations/{id}/cancel")
    public ResponseEntity<Reservation> cancelCustomerReservation(@PathVariable UUID id) {
        return ResponseEntity.ok(reservationService.cancelReservationByGuest(id));
    }

    @GetMapping("/tables/{outletId}")
    public ResponseEntity<List<RestaurantTable>> getTablesByOutlet(@PathVariable UUID outletId) {
        return ResponseEntity.ok(tableService.getTablesForStaff(null, outletId));
    }

    @PostMapping("/bills/{billId}/settle")
    public ResponseEntity<Bill> settleBillForCustomer(@PathVariable UUID billId, @RequestBody Map<String, Object> body) {
        String paymentId = body.get("razorpayPaymentId") != null ? body.get("razorpayPaymentId").toString() : "PAY_" + System.currentTimeMillis();
        String customerPhone = body.get("customerPhone") != null ? body.get("customerPhone").toString() : null;
        String json = "{\"method\":\"RAZORPAY\",\"paymentId\":\"" + paymentId + "\"}";

        Bill targetBill = billRepository.findById(billId)
                .or(() -> billRepository.findByOrderId(billId))
                .orElseGet(() -> {
                    try {
                        return billService.generateBill(billId, BigDecimal.ZERO, customerPhone, null, null);
                    } catch (Exception e) {
                        return null;
                    }
                });

        if (targetBill != null) {
            Bill settled = billService.settleBill(targetBill.getBillId(), json, customerPhone);
            try {
                Order order = orderRepository.findById(targetBill.getOrderId()).orElse(null);
                if (order != null) {
                    messagingTemplate.convertAndSend("/topic/orders", order);
                }
            } catch (Exception ignored) {}
            return ResponseEntity.ok(settled);
        }
        return ResponseEntity.ok(Bill.builder().isSettled(true).build());
    }

    // ==========================================
    // 7. FEEDBACK & REVIEWS
    // ==========================================

    @PostMapping("/feedback")
    public ResponseEntity<CustomerVisit> submitFeedback(@RequestBody CustomerFeedbackRequest request) {
        return ResponseEntity.ok(customerService.submitFeedback(request));
    }

    private void ensureDefaultMenuSeeded() {
        if (categoryRepository.count() == 0) {
            Category starters = categoryRepository.save(Category.builder().name("Starters").build());
            Category mains = categoryRepository.save(Category.builder().name("Main Course").build());
            Category italian = categoryRepository.save(Category.builder().name("Italian").build());
            Category drinks = categoryRepository.save(Category.builder().name("Drinks").build());
            Category desserts = categoryRepository.save(Category.builder().name("Desserts").build());

            UUID outletId = UUID.fromString("11111111-1111-1111-1111-111111111111");

            MenuItem springRolls = MenuItem.builder()
                    .name("Crispy Vegetable Spring Rolls")
                    .description("Crispy vegetable spring rolls served with sweet chili dipping sauce")
                    .category(starters)
                    .price(java.math.BigDecimal.valueOf(180.00))
                    .foodType("STARTER")
                    .isVeg(true)
                    .isAvailable(true)
                    .isSpecial(false)
                    .imageUrl("https://images.unsplash.com/photo-1599487488170-d11ec9c172f0?w=600&auto=format&fit=crop")
                    .outletId(outletId)
                    .build();

            MenuItem paneerButterMasala = MenuItem.builder()
                    .name("Paneer Butter Masala")
                    .description("Cottage cheese cubes in rich tomato butter gravy")
                    .category(mains)
                    .price(java.math.BigDecimal.valueOf(320.00))
                    .foodType("MAIN_COURSE")
                    .isVeg(true)
                    .isAvailable(true)
                    .isSpecial(true)
                    .imageUrl("https://images.unsplash.com/photo-1631452180519-c014fe946bc7?w=600&auto=format&fit=crop")
                    .outletId(outletId)
                    .build();

            MenuItem wagyuBurger = MenuItem.builder()
                    .name("Gourmet Wagyu Beef Burger")
                    .description("Artisan brioche bun with smoked cheddar and truffle mayo")
                    .category(mains)
                    .price(java.math.BigDecimal.valueOf(450.00))
                    .foodType("MAIN_COURSE")
                    .isVeg(false)
                    .isAvailable(true)
                    .isSpecial(true)
                    .imageUrl("https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600&auto=format&fit=crop")
                    .outletId(outletId)
                    .build();

            MenuItem margheritaPizza = MenuItem.builder()
                    .name("Wood-Fired Margherita Pizza")
                    .description("Fresh mozzarella, San Marzano tomato sauce, and fresh basil leaves")
                    .category(italian)
                    .price(java.math.BigDecimal.valueOf(380.00))
                    .foodType("MAIN_COURSE")
                    .isVeg(true)
                    .isAvailable(true)
                    .isSpecial(false)
                    .imageUrl("https://images.unsplash.com/photo-1604382354936-07c5d9983bd3?w=600&auto=format&fit=crop")
                    .outletId(outletId)
                    .build();

            MenuItem chickenBiryani = MenuItem.builder()
                    .name("Hyderabadi Dum Chicken Biryani")
                    .description("Fragrant basmati rice cooked with succulent chicken and aromatic spices")
                    .category(mains)
                    .price(java.math.BigDecimal.valueOf(350.00))
                    .foodType("MAIN_COURSE")
                    .isVeg(false)
                    .isAvailable(true)
                    .isSpecial(true)
                    .imageUrl("https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=600&auto=format&fit=crop")
                    .outletId(outletId)
                    .build();

            MenuItem tiramisu = MenuItem.builder()
                    .name("Classic Italian Tiramisu")
                    .description("Espresso-soaked savoiardi biscuits layered with whipped mascarpone cream")
                    .category(desserts)
                    .price(java.math.BigDecimal.valueOf(220.00))
                    .foodType("DESSERT")
                    .isVeg(true)
                    .isAvailable(true)
                    .isSpecial(true)
                    .imageUrl("https://images.unsplash.com/photo-1571877227200-a0d98ea607e9?w=600&auto=format&fit=crop")
                    .outletId(outletId)
                    .build();

            menuItemRepository.saveAll(List.of(springRolls, paneerButterMasala, wagyuBurger, margheritaPizza, chickenBiryani, tiramisu));
        }
    }
}
