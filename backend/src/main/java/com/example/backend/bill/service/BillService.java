package com.example.backend.bill.service;

import com.example.backend.bill.entity.Bill;
import com.example.backend.bill.entity.BillPayment;
import com.example.backend.bill.repository.BillRepository;
import com.example.backend.bill.repository.BillPaymentRepository;
import com.example.backend.bill.dto.*;
import com.example.backend.customer.entity.Customer;
import com.example.backend.customer.repository.CustomerRepository;
import com.example.backend.exception.*;
import com.example.backend.menu.entity.MenuItem;
import com.example.backend.menu.repository.MenuItemRepository;
import com.example.backend.order.entity.*;
import com.example.backend.order.repository.OrderItemRepository;
import com.example.backend.order.repository.OrderRepository;
import com.example.backend.order.service.OrderService;
import com.example.backend.report.entity.DayEndReport;
import com.example.backend.report.repository.DayEndReportRepository;
import com.example.backend.table.entity.RestaurantTable;
import com.example.backend.table.entity.TableStatus;
import com.example.backend.table.repository.RestaurantTableRepository;
import com.example.backend.table.service.TableService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import com.example.backend.customer.service.CustomerService;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.simp.SimpMessagingTemplate;

@Service
public class BillService {

    @Autowired(required = false)
    private SimpMessagingTemplate messagingTemplate;

    private final BillRepository billRepository;
    private final OrderRepository orderRepository;
    private final OrderItemRepository orderItemRepository;
    private final MenuItemRepository menuItemRepository;
    private final RestaurantTableRepository tableRepository;
    private final CustomerRepository customerRepository;
    private final DayEndReportRepository dayEndReportRepository;
    private final OrderService orderService;
    private final TableService tableService;
    private final BillPaymentRepository billPaymentRepository;
    private final CustomerService customerService;

    public BillService(BillRepository billRepository,
                       OrderRepository orderRepository,
                       OrderItemRepository orderItemRepository,
                       MenuItemRepository menuItemRepository,
                       RestaurantTableRepository tableRepository,
                       CustomerRepository customerRepository,
                       DayEndReportRepository dayEndReportRepository,
                       OrderService orderService,
                       TableService tableService,
                       BillPaymentRepository billPaymentRepository,
                       CustomerService customerService) {
        this.billRepository = billRepository;
        this.orderRepository = orderRepository;
        this.orderItemRepository = orderItemRepository;
        this.menuItemRepository = menuItemRepository;
        this.tableRepository = tableRepository;
        this.customerRepository = customerRepository;
        this.dayEndReportRepository = dayEndReportRepository;
        this.orderService = orderService;
        this.tableService = tableService;
        this.billPaymentRepository = billPaymentRepository;
        this.customerService = customerService;
    }

    public List<Bill> getAllBills() {
        return billRepository.findAll();
    }

    public Bill getBillById(UUID id) {
        return billRepository.findById(id)
                .or(() -> billRepository.findByOrderId(id))
                .orElseGet(() -> {
                    Order order = orderRepository.findById(id).orElse(null);
                    if (order != null) {
                        return generateBill(order.getOrderId(), BigDecimal.ZERO, order.getCustomerPhone(), null, null);
                    }
                    throw new RuntimeException("Bill not found for ID: " + id);
                });
    }

    private String cleanPaymentMethod(String paymentMethodJson) {
        if (paymentMethodJson == null || paymentMethodJson.trim().isEmpty()) {
            return "CASH";
        }
        String upper = paymentMethodJson.toUpperCase();
        if (upper.contains("RAZORPAY")) return "RAZORPAY";
        if (upper.contains("UPI")) return "UPI";
        if (upper.contains("CARD")) return "CARD";
        if (upper.contains("WALLET")) return "WALLET";
        if (upper.contains("CASH")) return "CASH";
        if (paymentMethodJson.length() > 30) return "ONLINE";
        return upper.trim();
    }

    @Transactional
    public Bill generateBill(UUID orderId, BigDecimal discountAmount, String customerPhone, Integer pointsToRedeem, String managerPin) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found"));

        if (discountAmount.compareTo(BigDecimal.ZERO) > 0) {
            orderService.validateManagerPin(managerPin);
        }

        Optional<Bill> existingBill = billRepository.findByOrderId(orderId);
        if (existingBill.isPresent()) {
            return existingBill.get();
        }

        List<OrderItem> items = orderItemRepository.findByOrderId(orderId);

        BigDecimal subtotal = BigDecimal.ZERO;
        BigDecimal cgstTotal = BigDecimal.ZERO;
        BigDecimal sgstTotal = BigDecimal.ZERO;

        for (OrderItem item : items) {
            if (item.getStatus() == OrderItemStatus.VOIDED) {
                continue;
            }
            MenuItem menuItem = menuItemRepository.findById(item.getMenuItemId())
                    .orElseThrow(() -> new RuntimeException("Menu item not found"));

            BigDecimal price = menuItem.getPrice();
            if (order.getOrderType() == OrderType.TAKEAWAY && menuItem.getPriceTakeaway() != null) {
                price = menuItem.getPriceTakeaway();
            } else if (order.getOrderType() == OrderType.DELIVERY && menuItem.getPriceDelivery() != null) {
                price = menuItem.getPriceDelivery();
            }

            BigDecimal itemTotal = price.multiply(BigDecimal.valueOf(item.getQuantity()));
            if (item.getDiscountAmount() != null) {
                itemTotal = itemTotal.subtract(item.getDiscountAmount());
            }
            if (item.isComplimentary()) {
                itemTotal = BigDecimal.ZERO;
            }
            if (itemTotal.compareTo(BigDecimal.ZERO) < 0) {
                itemTotal = BigDecimal.ZERO;
            }
            subtotal = subtotal.add(itemTotal);

            BigDecimal gstRate = menuItem.getGstRate() != null ? menuItem.getGstRate() : BigDecimal.ZERO;
            BigDecimal itemGst = itemTotal.multiply(gstRate).divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
            cgstTotal = cgstTotal.add(itemGst.divide(BigDecimal.valueOf(2), 2, RoundingMode.HALF_UP));
            sgstTotal = sgstTotal.add(itemGst.divide(BigDecimal.valueOf(2), 2, RoundingMode.HALF_UP));
        }

        BigDecimal loyaltyDiscount = BigDecimal.ZERO;
        Customer customer = null;
        if (customerPhone != null && !customerPhone.isEmpty() && pointsToRedeem != null && pointsToRedeem > 0) {
            orderService.validateManagerPin(managerPin);
            customer = customerRepository.findByPhone(customerPhone)
                    .orElseThrow(() -> new RuntimeException("Customer not found"));

            if (customer.getLoyaltyPoints() < pointsToRedeem) {
                throw new RuntimeException("Insufficient loyalty points");
            }
            if (pointsToRedeem % 50 != 0) {
                throw new RuntimeException("Points must be redeemed in multiples of 50");
            }
            loyaltyDiscount = BigDecimal.valueOf((pointsToRedeem / 50) * 5.0);
            customer.setLoyaltyPoints(customer.getLoyaltyPoints() - pointsToRedeem);
            customer.setPointsRedeemed(customer.getPointsRedeemed() + pointsToRedeem);
            customerRepository.save(customer);
        }

        BigDecimal unroundedTotal = subtotal.add(cgstTotal).add(sgstTotal).subtract(discountAmount).subtract(loyaltyDiscount);
        if (unroundedTotal.compareTo(BigDecimal.ZERO) < 0) {
            unroundedTotal = BigDecimal.ZERO;
        }

        BigDecimal total = unroundedTotal.setScale(0, RoundingMode.HALF_UP);
        BigDecimal roundOff = total.subtract(unroundedTotal);

        long count = billRepository.count();
        String billNumber = String.format("BILL-%06d", count + 1);

        Bill bill = Bill.builder()
                .orderId(orderId)
                .billNumber(billNumber)
                .subtotal(subtotal)
                .cgst(cgstTotal)
                .sgst(sgstTotal)
                .discount(discountAmount)
                .loyaltyDiscount(loyaltyDiscount)
                .roundOff(roundOff)
                .total(total)
                .isSettled(false)
                .createdAt(LocalDateTime.now())
                .build();

        Bill savedBill = billRepository.save(bill);

        if (order.getOrderType() == OrderType.DINE_IN) {
            order.setStatus(OrderStatus.BILLED);
        }
        order.setBilledAt(LocalDateTime.now());
        orderRepository.save(order);

        return savedBill;
    }

    @Transactional
    public Bill settleBill(UUID billId, String paymentMethodJson, String customerPhone) {
        Bill bill = getBillById(billId);
        if (bill.isSettled()) {
            throw new BillAlreadySettledException("Bill is already settled");
        }

        bill.setSettled(true);
        bill.setSettledAt(LocalDateTime.now());
        bill.setPaymentMethod(paymentMethodJson);
        Bill savedBill = billRepository.save(bill);

        BillPayment split = BillPayment.builder()
                .billId(savedBill.getBillId())
                .paymentMethod(cleanPaymentMethod(paymentMethodJson))
                .amount(bill.getTotal())
                .build();
        billPaymentRepository.save(split);

        completeOrderSettlement(bill, customerPhone);
        return savedBill;
    }

    @Transactional
    public Bill settleBillSplit(UUID billId, SettleBillRequest request) {
        Bill bill = getBillById(billId);
        if (bill.isSettled()) {
            throw new BillAlreadySettledException("Bill is already settled");
        }

        if (request.getSplits() == null || request.getSplits().isEmpty()) {
            throw new RuntimeException("At least one payment split is required");
        }
        if (request.getSplits().size() > 4) {
            throw new RuntimeException("Maximum of 4 split payment methods allowed");
        }

        BigDecimal splitsTotal = BigDecimal.ZERO;
        StringBuilder serializedMethod = new StringBuilder();
        for (BillPaymentSplitRequest splitReq : request.getSplits()) {
            splitsTotal = splitsTotal.add(splitReq.getAmount());
            if (serializedMethod.length() > 0) {
                serializedMethod.append(", ");
            }
            serializedMethod.append(splitReq.getPaymentMethod()).append(": ").append(splitReq.getAmount());
        }

        if (splitsTotal.compareTo(bill.getTotal()) != 0) {
            throw new RuntimeException("Total of split payments (" + splitsTotal + ") must equal bill total (" + bill.getTotal() + ")");
        }

        bill.setSettled(true);
        bill.setSettledAt(LocalDateTime.now());
        bill.setPaymentMethod(serializedMethod.toString());
        
        if (request.getTipAmount() != null) {
            bill.setTipAmount(request.getTipAmount());
        }
        if (request.getCashReceived() != null) {
            bill.setCashReceived(request.getCashReceived());
        }
        if (request.getChangeGiven() != null) {
            bill.setChangeGiven(request.getChangeGiven());
        }

        Bill savedBill = billRepository.save(bill);

        for (BillPaymentSplitRequest splitReq : request.getSplits()) {
            BillPayment split = BillPayment.builder()
                    .billId(billId)
                    .paymentMethod(splitReq.getPaymentMethod().toUpperCase())
                    .amount(splitReq.getAmount())
                    .transactionReference(splitReq.getTransactionReference())
                    .build();
            billPaymentRepository.save(split);
        }

        completeOrderSettlement(bill, request.getCustomerPhone());
        return savedBill;
    }

    private void completeOrderSettlement(Bill bill, String customerPhone) {
        Order order = orderRepository.findById(bill.getOrderId())
                .orElseThrow(() -> new RuntimeException("Order not found"));
        
        List<Bill> allBills = billRepository.findAllByOrderId(bill.getOrderId());
        boolean allSettled = allBills.stream().allMatch(Bill::isSettled);

        if (allSettled) {
            order.setPaymentStatus("PAID");

            if (order.getOrderType() == OrderType.DELIVERY || order.getOrderType() == OrderType.DIRECT_ONLINE || order.getOrderType() == OrderType.TAKEAWAY) {
                // Online delivery / takeaway orders are prepaid: the kitchen must cook the food!
                // Keep fulfillment status active: if NEW, DRAFT, BILLED, or prematurely PAID, advance/maintain PREPARING
                if (order.getStatus() == OrderStatus.NEW || order.getStatus() == OrderStatus.DRAFT || order.getStatus() == OrderStatus.BILLED || order.getStatus() == OrderStatus.PAID) {
                    order.setStatus(OrderStatus.PREPARING);
                }
                order.setKotFiredAt(LocalDateTime.now());

                // Assign all order items to PREPARING for kitchen
                List<OrderItem> items = orderItemRepository.findByOrderId(order.getOrderId());
                for (OrderItem item : items) {
                    if (item.getStatus() == OrderItemStatus.PENDING || item.getStatus() == null) {
                        item.setStatus(OrderItemStatus.PREPARING);
                        orderItemRepository.save(item);
                    }
                }

                orderService.logTimelineEvent(order.getOrderId(), "PAYMENT_SUCCESS",
                        "Payment of ₹" + bill.getTotal() + " received successfully (" + cleanPaymentMethod(bill.getPaymentMethod()) + ").", "PaymentGateway");
                orderService.logTimelineEvent(order.getOrderId(), "ASSIGNED_TO_KITCHEN",
                        "Order assigned to kitchen. Chef has started preparing your food.", "Kitchen");
            } else {
                List<OrderItem> items = orderItemRepository.findByOrderId(order.getOrderId());
                boolean anyCooking = items.stream().anyMatch(i -> i.getStatus() == OrderItemStatus.PREPARING || i.getStatus() == OrderItemStatus.PENDING);
                if (!anyCooking) {
                    order.setStatus(OrderStatus.PAID);
                    if (order.getTableId() != null) {
                        tableService.releaseTable(order.getTableId());
                    }
                } else {
                    order.setStatus(OrderStatus.PREPARING);
                }
            }
            Order savedOrder = orderRepository.save(order);

            // Broadcast real-time update to Kitchen Display and POS dashboards
            try {
                if (messagingTemplate != null) {
                    messagingTemplate.convertAndSend("/topic/orders", savedOrder);
                    messagingTemplate.convertAndSend("/topic/alerts", (Object) Map.of(
                            "type", "NEW_ORDER",
                            "orderId", savedOrder.getOrderId(),
                            "message", "New paid order #" + savedOrder.getOrderId().toString().substring(0, 8) + " assigned to kitchen!"
                    ));
                }
            } catch (Exception ignored) {}
        }

        if (customerPhone != null && !customerPhone.isEmpty()) {
            Customer customer = customerRepository.findByPhone(customerPhone).orElse(null);
            if (customer != null) {
                int pointsAwarded = bill.getTotal().divide(BigDecimal.valueOf(10), 0, RoundingMode.DOWN).intValue();
                customer.setLoyaltyPoints(customer.getLoyaltyPoints() + pointsAwarded);
                customer.setPointsEarned(customer.getPointsEarned() + pointsAwarded);
                customer.setTotalSpend(customer.getTotalSpend().add(bill.getTotal()));
                customer.setTotalVisits(customer.getTotalVisits() + 1);
                customer.setLastVisitAt(LocalDateTime.now());
                customerRepository.save(customer);

                // Log Visit in Customer Visit History
                RestaurantTable table = order.getTableId() != null ? tableRepository.findById(order.getTableId()).orElse(null) : null;
                String tableName = table != null ? table.getTableNumber() : "N/A";
                List<OrderItem> items = orderItemRepository.findByOrderId(order.getOrderId());
                StringBuilder itemNames = new StringBuilder();
                for (OrderItem item : items) {
                    if (item.getStatus() != OrderItemStatus.VOIDED) {
                        MenuItem mi = menuItemRepository.findById(item.getMenuItemId()).orElse(null);
                        if (mi != null) {
                            if (itemNames.length() > 0) itemNames.append(", ");
                            itemNames.append(mi.getName());
                        }
                    }
                }

                customerService.logVisit(customer.getCustomerId(), order.getOrderId(), tableName, itemNames.toString(), bill.getTotal());
            }
        }
    }

    @Transactional
    public Bill voidBill(UUID billId, String managerPin) {
        orderService.validateManagerPin(managerPin);
        Bill bill = getBillById(billId);

        Order order = orderRepository.findById(bill.getOrderId())
                .orElseThrow(() -> new RuntimeException("Order not found"));
        order.setStatus(OrderStatus.CANCELLED);
        orderRepository.save(order);

        if (order.getOrderType() == OrderType.DINE_IN && order.getTableId() != null) {
            tableService.releaseTable(order.getTableId());
        }

        System.out.println(String.format("[REFUND] Refunded amount %s of voided Bill %s to original payment method", 
                bill.getTotal(), bill.getBillId()));

        billRepository.delete(bill);
        return bill;
    }

    @Transactional
    public DayEndReport generateZReport(LocalDate date, UUID managerId) {
        List<Bill> settledBills = billRepository.findAll().stream()
                .filter(b -> b.isSettled() && b.getSettledAt().toLocalDate().equals(date))
                .toList();

        BigDecimal totalSales = BigDecimal.ZERO;
        BigDecimal totalDiscounts = BigDecimal.ZERO;
        BigDecimal cashCollected = BigDecimal.ZERO;
        BigDecimal cardCollected = BigDecimal.ZERO;
        BigDecimal upiCollected = BigDecimal.ZERO;
        BigDecimal walletCollected = BigDecimal.ZERO;
        BigDecimal totalComplimentaryValue = BigDecimal.ZERO;
        BigDecimal totalTips = BigDecimal.ZERO;
        int totalCovers = 0;

        for (Bill b : settledBills) {
            totalSales = totalSales.add(b.getTotal());
            totalDiscounts = totalDiscounts.add(b.getDiscount()).add(b.getLoyaltyDiscount());
            totalTips = totalTips.add(b.getTipAmount());

            Order order = orderRepository.findById(b.getOrderId()).orElse(null);
            if (order != null) {
                totalCovers += order.getCovers();
            }

            List<OrderItem> items = orderItemRepository.findByOrderId(b.getOrderId());
            for (OrderItem item : items) {
                if (item.isComplimentary()) {
                    MenuItem menuItem = menuItemRepository.findById(item.getMenuItemId()).orElse(null);
                    if (menuItem != null) {
                        BigDecimal price = menuItem.getPrice();
                        if (order != null) {
                            if (order.getOrderType() == OrderType.TAKEAWAY && menuItem.getPriceTakeaway() != null) {
                                price = menuItem.getPriceTakeaway();
                            } else if (order.getOrderType() == OrderType.DELIVERY && menuItem.getPriceDelivery() != null) {
                                price = menuItem.getPriceDelivery();
                            }
                        }
                        totalComplimentaryValue = totalComplimentaryValue.add(price.multiply(BigDecimal.valueOf(item.getQuantity())));
                    }
                }
            }

            List<BillPayment> payments = billPaymentRepository.findByBillId(b.getBillId());
            if (!payments.isEmpty()) {
                for (BillPayment p : payments) {
                    String method = p.getPaymentMethod().toUpperCase();
                    if (method.contains("CASH")) {
                        cashCollected = cashCollected.add(p.getAmount());
                    } else if (method.contains("CARD") || method.contains("PINE")) {
                        cardCollected = cardCollected.add(p.getAmount());
                    } else if (method.contains("UPI") || method.contains("RAZOR")) {
                        upiCollected = upiCollected.add(p.getAmount());
                    } else {
                        walletCollected = walletCollected.add(p.getAmount());
                    }
                }
            } else {
                String payMethod = b.getPaymentMethod();
                if (payMethod != null) {
                    if (payMethod.toUpperCase().contains("CASH")) {
                        cashCollected = cashCollected.add(b.getTotal());
                    } else if (payMethod.toUpperCase().contains("CARD") || payMethod.toUpperCase().contains("PINE")) {
                        cardCollected = cardCollected.add(b.getTotal());
                    } else if (payMethod.toUpperCase().contains("UPI") || payMethod.toUpperCase().contains("RAZOR")) {
                        upiCollected = upiCollected.add(b.getTotal());
                    } else {
                        walletCollected = walletCollected.add(b.getTotal());
                    }
                } else {
                    cashCollected = cashCollected.add(b.getTotal());
                }
            }
        }

        DayEndReport report = DayEndReport.builder()
                .outletId(UUID.randomUUID())
                .reportDate(date)
                .totalSales(totalSales)
                .totalCovers(totalCovers)
                .totalDiscounts(totalDiscounts)
                .totalVoids(BigDecimal.ZERO)
                .totalComplimentaryValue(totalComplimentaryValue)
                .walletCollected(walletCollected)
                .totalTips(totalTips)
                .cashCollected(cashCollected)
                .cardCollected(cardCollected)
                .upiCollected(upiCollected)
                .generatedBy(managerId)
                .generatedAt(LocalDateTime.now())
                .build();

        return dayEndReportRepository.save(report);
    }

    @Transactional
    public List<Bill> splitBillEqually(UUID orderId, int numGuests, String managerPin) {
        if (numGuests <= 1) {
            throw new RuntimeException("Number of guests must be greater than 1 to split bill");
        }
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found"));

        Optional<Bill> existing = billRepository.findByOrderId(orderId);
        if (existing.isPresent()) {
            billRepository.delete(existing.get());
        }

        List<OrderItem> items = orderItemRepository.findByOrderId(orderId);
        BigDecimal subtotal = BigDecimal.ZERO;
        BigDecimal cgstTotal = BigDecimal.ZERO;
        BigDecimal sgstTotal = BigDecimal.ZERO;

        for (OrderItem item : items) {
            if (item.getStatus() == OrderItemStatus.VOIDED) continue;
            MenuItem menuItem = menuItemRepository.findById(item.getMenuItemId()).orElseThrow();
            BigDecimal price = menuItem.getPrice();
            if (order.getOrderType() == OrderType.TAKEAWAY && menuItem.getPriceTakeaway() != null) {
                price = menuItem.getPriceTakeaway();
            } else if (order.getOrderType() == OrderType.DELIVERY && menuItem.getPriceDelivery() != null) {
                price = menuItem.getPriceDelivery();
            }
            BigDecimal itemTotal = price.multiply(BigDecimal.valueOf(item.getQuantity()));
            if (item.getDiscountAmount() != null) {
                itemTotal = itemTotal.subtract(item.getDiscountAmount());
            }
            if (item.isComplimentary()) {
                itemTotal = BigDecimal.ZERO;
            }
            subtotal = subtotal.add(itemTotal);

            BigDecimal gstRate = menuItem.getGstRate() != null ? menuItem.getGstRate() : BigDecimal.ZERO;
            BigDecimal itemGst = itemTotal.multiply(gstRate).divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
            cgstTotal = cgstTotal.add(itemGst.divide(BigDecimal.valueOf(2), 2, RoundingMode.HALF_UP));
            sgstTotal = sgstTotal.add(itemGst.divide(BigDecimal.valueOf(2), 2, RoundingMode.HALF_UP));
        }

        BigDecimal guestSubtotal = subtotal.divide(BigDecimal.valueOf(numGuests), 2, RoundingMode.HALF_UP);
        BigDecimal guestCgst = cgstTotal.divide(BigDecimal.valueOf(numGuests), 2, RoundingMode.HALF_UP);
        BigDecimal guestSgst = sgstTotal.divide(BigDecimal.valueOf(numGuests), 2, RoundingMode.HALF_UP);

        List<Bill> splitBills = new ArrayList<>();
        long baseCount = billRepository.count();

        for (int i = 1; i <= numGuests; i++) {
            BigDecimal unroundedChildTotal = guestSubtotal.add(guestCgst).add(guestSgst);
            BigDecimal roundedChildTotal = unroundedChildTotal.setScale(0, RoundingMode.HALF_UP);
            BigDecimal childRoundOff = roundedChildTotal.subtract(unroundedChildTotal);

            String billNumber = String.format("BILL-%06d-%d", baseCount + 1, i);
            Bill childBill = Bill.builder()
                    .orderId(orderId)
                    .billNumber(billNumber)
                    .subtotal(guestSubtotal)
                    .cgst(guestCgst)
                    .sgst(guestSgst)
                    .discount(BigDecimal.ZERO)
                    .loyaltyDiscount(BigDecimal.ZERO)
                    .roundOff(childRoundOff)
                    .total(roundedChildTotal)
                    .isSettled(false)
                    .createdAt(LocalDateTime.now())
                    .build();

            splitBills.add(billRepository.save(childBill));
        }

        order.setStatus(OrderStatus.BILLED);
        order.setBilledAt(LocalDateTime.now());
        orderRepository.save(order);

        return splitBills;
    }

    @Transactional
    public List<Bill> splitBillByItems(UUID orderId, List<List<UUID>> itemGroups, String managerPin) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found"));

        Optional<Bill> existing = billRepository.findByOrderId(orderId);
        if (existing.isPresent()) {
            billRepository.delete(existing.get());
        }

        List<Bill> splitBills = new java.util.ArrayList<>();
        long baseCount = billRepository.count();

        for (int index = 0; index < itemGroups.size(); index++) {
            List<UUID> itemIds = itemGroups.get(index);
            BigDecimal subtotal = BigDecimal.ZERO;
            BigDecimal cgstTotal = BigDecimal.ZERO;
            BigDecimal sgstTotal = BigDecimal.ZERO;

            for (UUID itemId : itemIds) {
                OrderItem item = orderItemRepository.findById(itemId)
                        .orElseThrow(() -> new RuntimeException("OrderItem not found"));
                MenuItem menuItem = menuItemRepository.findById(item.getMenuItemId()).orElseThrow();
                BigDecimal price = menuItem.getPrice();
                if (order.getOrderType() == OrderType.TAKEAWAY && menuItem.getPriceTakeaway() != null) {
                    price = menuItem.getPriceTakeaway();
                } else if (order.getOrderType() == OrderType.DELIVERY && menuItem.getPriceDelivery() != null) {
                    price = menuItem.getPriceDelivery();
                }

                BigDecimal itemTotal = price.multiply(BigDecimal.valueOf(item.getQuantity()));
                if (item.getDiscountAmount() != null) {
                    itemTotal = itemTotal.subtract(item.getDiscountAmount());
                }
                if (item.isComplimentary()) {
                    itemTotal = BigDecimal.ZERO;
                }
                subtotal = subtotal.add(itemTotal);

                BigDecimal gstRate = menuItem.getGstRate() != null ? menuItem.getGstRate() : BigDecimal.ZERO;
                BigDecimal itemGst = itemTotal.multiply(gstRate).divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
                cgstTotal = cgstTotal.add(itemGst.divide(BigDecimal.valueOf(2), 2, RoundingMode.HALF_UP));
                sgstTotal = sgstTotal.add(itemGst.divide(BigDecimal.valueOf(2), 2, RoundingMode.HALF_UP));
            }

            BigDecimal unroundedChildTotal = subtotal.add(cgstTotal).add(sgstTotal);
            BigDecimal roundedChildTotal = unroundedChildTotal.setScale(0, RoundingMode.HALF_UP);
            BigDecimal childRoundOff = roundedChildTotal.subtract(unroundedChildTotal);

            char suffix = (char) ('A' + index);
            String billNumber = String.format("BILL-%06d-%c", baseCount + 1, suffix);
            Bill childBill = Bill.builder()
                    .orderId(orderId)
                    .billNumber(billNumber)
                    .subtotal(subtotal)
                    .cgst(cgstTotal)
                    .sgst(sgstTotal)
                    .discount(BigDecimal.ZERO)
                    .loyaltyDiscount(BigDecimal.ZERO)
                    .roundOff(childRoundOff)
                    .total(roundedChildTotal)
                    .isSettled(false)
                    .createdAt(LocalDateTime.now())
                    .build();

            splitBills.add(billRepository.save(childBill));
        }

        order.setStatus(OrderStatus.BILLED);
        order.setBilledAt(LocalDateTime.now());
        orderRepository.save(order);

        return splitBills;
    }

    public String getReceiptText(UUID billId) {
        Bill bill = getBillById(billId);
        Order order = orderRepository.findById(bill.getOrderId()).orElseThrow();
        List<OrderItem> items = orderItemRepository.findByOrderId(bill.getOrderId());
        
        RestaurantTable table = order.getTableId() != null ? tableRepository.findById(order.getTableId()).orElse(null) : null;
        String tableName = table != null ? table.getTableNumber() : "N/A";

        StringBuilder receipt = new StringBuilder();
        receipt.append("========================================\n");
        receipt.append("             SPICE HAVEN               \n");
        receipt.append("      FSSAI Lic No: FSSAI-12345678901234\n");
        receipt.append("      GSTIN: GSTIN-27AAAAA1111A1Z1      \n");
        receipt.append("========================================\n");
        receipt.append("Bill No: ").append(bill.getBillNumber()).append("\n");
        receipt.append("Date: ").append(bill.getCreatedAt().toString()).append("\n");
        receipt.append("Table: ").append(tableName).append("\n");
        receipt.append("----------------------------------------\n");
        receipt.append(String.format("%-18s %3s %8s %8s\n", "Item", "Qty", "Price", "Total"));
        receipt.append("----------------------------------------\n");

        for (OrderItem item : items) {
            if (item.getStatus() == OrderItemStatus.VOIDED) continue;
            MenuItem menuItem = menuItemRepository.findById(item.getMenuItemId()).orElse(null);
            String name = menuItem != null ? menuItem.getName() : "Unknown";
            
            BigDecimal price = menuItem != null ? menuItem.getPrice() : BigDecimal.ZERO;
            if (order.getOrderType() == OrderType.TAKEAWAY && menuItem != null && menuItem.getPriceTakeaway() != null) {
                price = menuItem.getPriceTakeaway();
            } else if (order.getOrderType() == OrderType.DELIVERY && menuItem != null && menuItem.getPriceDelivery() != null) {
                price = menuItem.getPriceDelivery();
            }

            BigDecimal itemTotal = price.multiply(BigDecimal.valueOf(item.getQuantity()));
            receipt.append(String.format("%-18.18s %3d %8.2f %8.2f\n", name, item.getQuantity(), price, itemTotal));
            if (item.getModifiers() != null && !item.getModifiers().isEmpty()) {
                receipt.append("  * ").append(item.getModifiers()).append("\n");
            }
        }
        receipt.append("----------------------------------------\n");
        receipt.append(String.format("%-25s %13.2f\n", "Subtotal:", bill.getSubtotal()));
        receipt.append(String.format("%-25s %13.2f\n", "CGST:", bill.getCgst()));
        receipt.append(String.format("%-25s %13.2f\n", "SGST:", bill.getSgst()));
        if (bill.getDiscount().compareTo(BigDecimal.ZERO) > 0) {
            receipt.append(String.format("%-25s %13.2f\n", "Discount:", bill.getDiscount().negate()));
        }
        if (bill.getLoyaltyDiscount().compareTo(BigDecimal.ZERO) > 0) {
            receipt.append(String.format("%-25s %13.2f\n", "Loyalty:", bill.getLoyaltyDiscount().negate()));
        }
        if (bill.getRoundOff().compareTo(BigDecimal.ZERO) != 0) {
            receipt.append(String.format("%-25s %13.2f\n", "Round-Off:", bill.getRoundOff()));
        }
        if (bill.getTipAmount().compareTo(BigDecimal.ZERO) > 0) {
            receipt.append(String.format("%-25s %13.2f\n", "Tips:", bill.getTipAmount()));
        }
        receipt.append("----------------------------------------\n");
        receipt.append(String.format("%-25s %13.2f\n", "TOTAL AMOUNT:", bill.getTotal().add(bill.getTipAmount())));
        receipt.append("========================================\n");
        receipt.append("      Thank you! Visit Again.           \n");
        receipt.append("========================================\n");

        return receipt.toString();
    }

    public String sendDigitalReceipt(UUID billId, String phoneNumber) {
        String receiptLink = "http://deluxediner.com/receipt/" + billId;
        System.out.println(String.format("[DIGITAL RECEIPT] Sent link %s to %s", receiptLink, phoneNumber));
        return receiptLink;
    }

    public CashDrawerReconciliation reconcileCashDrawer(LocalDate date, BigDecimal startingCash) {
        List<Bill> settledBills = billRepository.findAll().stream()
                .filter(b -> b.isSettled() && b.getSettledAt().toLocalDate().equals(date))
                .toList();

        BigDecimal cashCollected = BigDecimal.ZERO;

        for (Bill b : settledBills) {
            List<BillPayment> payments = billPaymentRepository.findByBillId(b.getBillId());
            if (!payments.isEmpty()) {
                for (BillPayment p : payments) {
                    if (p.getPaymentMethod().toUpperCase().contains("CASH")) {
                        cashCollected = cashCollected.add(p.getAmount());
                    }
                }
            } else {
                String payMethod = b.getPaymentMethod();
                if (payMethod == null || payMethod.toUpperCase().contains("CASH")) {
                    cashCollected = cashCollected.add(b.getTotal());
                }
            }
        }

        BigDecimal expected = startingCash.add(cashCollected);

        return CashDrawerReconciliation.builder()
                .date(date)
                .startingCash(startingCash)
                .cashCollected(cashCollected)
                .expectedCashInDrawer(expected)
                .build();
    }
}
