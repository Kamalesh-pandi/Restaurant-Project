
path = r'C:\Restaurant Project\backend\src\main\java\com\example\backend\customer\controller\CustomerAppController.java'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Import SimpMessagingTemplate
if 'import org.springframework.messaging.simp.SimpMessagingTemplate;' not in content:
    content = content.replace(
        'import org.springframework.http.ResponseEntity;',
        'import org.springframework.http.ResponseEntity;\nimport org.springframework.messaging.simp.SimpMessagingTemplate;'
    )

# 2. Add field & constructor parameter
old_fields = """    private final BillService billService;
    private final BillRepository billRepository;

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
                                 BillRepository billRepository) {"""

new_fields = """    private final BillService billService;
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
                                 SimpMessagingTemplate messagingTemplate) {"""

content = content.replace(old_fields, new_fields)

content = content.replace(
    'this.billRepository = billRepository;\n    }',
    'this.billRepository = billRepository;\n        this.messagingTemplate = messagingTemplate;\n    }'
)

# 3. Add kotFiredAt(LocalDateTime.now()) in placeDirectOrder
old_order_build = """.estimatedDeliveryTime(LocalDateTime.now().plusMinutes(35))
                .isTraining(false)
                .build();"""

new_order_build = """.estimatedDeliveryTime(LocalDateTime.now().plusMinutes(35))
                .kotFiredAt(LocalDateTime.now())
                .isTraining(false)
                .build();"""

content = content.replace(old_order_build, new_order_build)

# 4. Add websocket broadcast in placeDirectOrder
old_timeline_call = """        orderService.logTimelineEvent(savedOrder.getOrderId(), "DIRECT_APP_ORDER_PLACED",
                "Direct customer app order placed by " + request.getCustomerName() + " (" + request.getCustomerPhone() + ")", "CustomerApp");

        try {
            billService.generateBill(savedOrder.getOrderId(), BigDecimal.ZERO, request.getCustomerPhone(), null, null);
        } catch (Exception ignored) {}"""

new_timeline_call = """        orderService.logTimelineEvent(savedOrder.getOrderId(), "DIRECT_APP_ORDER_PLACED",
                "Direct customer app order placed by " + request.getCustomerName() + " (" + request.getCustomerPhone() + ")", "CustomerApp");

        try {
            billService.generateBill(savedOrder.getOrderId(), BigDecimal.ZERO, request.getCustomerPhone(), null, null);
        } catch (Exception ignored) {}

        try {
            messagingTemplate.convertAndSend("/topic/orders", savedOrder);
        } catch (Exception ignored) {}"""

content = content.replace(old_timeline_call, new_timeline_call)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("CUSTOMER APP CONTROLLER UPDATED")
