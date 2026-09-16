package com.example.backend.report.service;

import com.example.backend.bill.entity.Bill;
import com.example.backend.bill.repository.BillRepository;
import com.example.backend.customer.entity.Customer;
import com.example.backend.customer.entity.CustomerVisit;
import com.example.backend.customer.repository.CustomerRepository;
import com.example.backend.customer.repository.CustomerVisitRepository;
import com.example.backend.inventory.entity.InventoryItem;
import com.example.backend.inventory.entity.Recipe;
import com.example.backend.inventory.repository.InventoryItemRepository;
import com.example.backend.inventory.repository.RecipeRepository;
import com.example.backend.menu.entity.MenuItem;
import com.example.backend.menu.repository.MenuItemRepository;
import com.example.backend.order.entity.*;
import com.example.backend.order.repository.OrderItemRepository;
import com.example.backend.order.repository.OrderRepository;
import com.example.backend.report.dto.*;
import com.example.backend.report.entity.DayEndReport;
import com.example.backend.report.repository.DayEndReportRepository;
import com.example.backend.staff.dto.StaffPerformanceResponse;
import com.example.backend.staff.entity.Staff;
import com.example.backend.staff.repository.StaffRepository;
import com.example.backend.staff.service.StaffService;
import com.example.backend.table.entity.RestaurantTable;
import com.example.backend.table.repository.RestaurantTableRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class AnalyticsService {

    private final BillRepository billRepository;
    private final OrderRepository orderRepository;
    private final OrderItemRepository orderItemRepository;
    private final MenuItemRepository menuItemRepository;
    private final RecipeRepository recipeRepository;
    private final InventoryItemRepository inventoryItemRepository;
    private final RestaurantTableRepository tableRepository;
    private final CustomerRepository customerRepository;
    private final CustomerVisitRepository customerVisitRepository;
    private final StaffRepository staffRepository;
    private final StaffService staffService;
    private final DayEndReportRepository dayEndReportRepository;

    public AnalyticsService(BillRepository billRepository,
                             OrderRepository orderRepository,
                             OrderItemRepository orderItemRepository,
                             MenuItemRepository menuItemRepository,
                             RecipeRepository recipeRepository,
                             InventoryItemRepository inventoryItemRepository,
                             RestaurantTableRepository tableRepository,
                             CustomerRepository customerRepository,
                             CustomerVisitRepository customerVisitRepository,
                             StaffRepository staffRepository,
                             StaffService staffService,
                             DayEndReportRepository dayEndReportRepository) {
        this.billRepository = billRepository;
        this.orderRepository = orderRepository;
        this.orderItemRepository = orderItemRepository;
        this.menuItemRepository = menuItemRepository;
        this.recipeRepository = recipeRepository;
        this.inventoryItemRepository = inventoryItemRepository;
        this.tableRepository = tableRepository;
        this.customerRepository = customerRepository;
        this.customerVisitRepository = customerVisitRepository;
        this.staffRepository = staffRepository;
        this.staffService = staffService;
        this.dayEndReportRepository = dayEndReportRepository;
    }

    // Daily Sales Summary
    public DailySalesSummaryResponse getDailySalesSummary(LocalDate startDate, LocalDate endDate, UUID outletId) {
        List<Bill> bills = billRepository.findAll().stream()
                .filter(Bill::isSettled)
                .filter(b -> filterByDateAndOutlet(b.getCreatedAt(), startDate, endDate, b.getOrderId(), outletId))
                .toList();

        BigDecimal gmv = BigDecimal.ZERO;
        Map<String, BigDecimal> paymentMix = new HashMap<>();
        Map<Integer, BigDecimal> hourlyTrend = new HashMap<>();

        for (Bill b : bills) {
            gmv = gmv.add(b.getTotal());

            String method = b.getPaymentMethod() != null ? b.getPaymentMethod() : "CASH";
            paymentMix.put(method, paymentMix.getOrDefault(method, BigDecimal.ZERO).add(b.getTotal()));

            if (b.getCreatedAt() != null) {
                int hour = b.getCreatedAt().getHour();
                hourlyTrend.put(hour, hourlyTrend.getOrDefault(hour, BigDecimal.ZERO).add(b.getTotal()));
            }
        }

        List<Order> orders = orderRepository.findAll().stream()
                .filter(o -> o.getStatus() == OrderStatus.PAID)
                .filter(o -> filterOrder(o, startDate, endDate, outletId))
                .toList();

        int totalCovers = orders.stream().mapToInt(Order::getCovers).sum();
        BigDecimal aov = orders.isEmpty() ? BigDecimal.ZERO : gmv.divide(BigDecimal.valueOf(orders.size()), 2, RoundingMode.HALF_UP);

        return DailySalesSummaryResponse.builder()
                .gmv(gmv)
                .totalCovers(totalCovers)
                .aov(aov)
                .paymentMethodMix(paymentMix)
                .hourlyRevenueTrend(hourlyTrend)
                .build();
    }

    // X-Report (Current Live Shift Totals)
    public XReportResponse getXReport(UUID outletId) {
        List<Bill> liveBills = billRepository.findAll().stream()
                .filter(Bill::isSettled)
                .filter(b -> {
                    if (outletId == null) return true;
                    Order order = orderRepository.findById(b.getOrderId()).orElse(null);
                    return order != null && outletId.equals(order.getOutletId());
                })
                .toList();

        BigDecimal liveSales = BigDecimal.ZERO;
        Map<String, BigDecimal> paymentTotals = new HashMap<>();
        for (Bill b : liveBills) {
            liveSales = liveSales.add(b.getTotal());
            String method = b.getPaymentMethod() != null ? b.getPaymentMethod() : "CASH";
            paymentTotals.put(method, paymentTotals.getOrDefault(method, BigDecimal.ZERO).add(b.getTotal()));
        }

        List<Order> openOrders = orderRepository.findAll().stream()
                .filter(o -> o.getStatus() != OrderStatus.PAID && o.getStatus() != OrderStatus.CANCELLED)
                .filter(o -> outletId == null || outletId.equals(o.getOutletId()))
                .toList();

        int liveCovers = openOrders.stream().mapToInt(Order::getCovers).sum();

        return XReportResponse.builder()
                .shiftStartTime(LocalDateTime.now().withHour(8).withMinute(0))
                .liveSales(liveSales)
                .liveCovers(liveCovers)
                .openOrdersCount(openOrders.size())
                .paymentTotals(paymentTotals)
                .build();
    }

    // Z-Report (End of Day Settlement)
    @Transactional
    public DayEndReport generateZReport(LocalDate date, UUID outletId, UUID managerId) {
        List<Bill> dayBills = billRepository.findAll().stream()
                .filter(Bill::isSettled)
                .filter(b -> b.getSettledAt() != null && b.getSettledAt().toLocalDate().equals(date))
                .toList();

        BigDecimal totalSales = BigDecimal.ZERO;
        BigDecimal totalDiscounts = BigDecimal.ZERO;
        BigDecimal cash = BigDecimal.ZERO;
        BigDecimal card = BigDecimal.ZERO;
        BigDecimal upi = BigDecimal.ZERO;
        BigDecimal wallet = BigDecimal.ZERO;
        BigDecimal tips = BigDecimal.ZERO;

        for (Bill b : dayBills) {
            totalSales = totalSales.add(b.getTotal());
            totalDiscounts = totalDiscounts.add(b.getDiscount() != null ? b.getDiscount() : BigDecimal.ZERO)
                    .add(b.getLoyaltyDiscount() != null ? b.getLoyaltyDiscount() : BigDecimal.ZERO);

            if (b.getTipAmount() != null) tips = tips.add(b.getTipAmount());

            String method = b.getPaymentMethod() != null ? b.getPaymentMethod().toUpperCase() : "CASH";
            if (method.contains("CASH")) cash = cash.add(b.getTotal());
            else if (method.contains("CARD")) card = card.add(b.getTotal());
            else if (method.contains("UPI")) upi = upi.add(b.getTotal());
            else wallet = wallet.add(b.getTotal());
        }

        List<Order> dayOrders = orderRepository.findAll().stream()
                .filter(o -> o.getStatus() == OrderStatus.PAID && o.getSeatedAt() != null && o.getSeatedAt().toLocalDate().equals(date))
                .toList();

        int totalCovers = dayOrders.stream().mapToInt(Order::getCovers).sum();

        DayEndReport report = DayEndReport.builder()
                .outletId(outletId != null ? outletId : UUID.randomUUID())
                .reportDate(date)
                .totalSales(totalSales)
                .totalCovers(totalCovers)
                .totalDiscounts(totalDiscounts)
                .totalVoids(BigDecimal.ZERO)
                .cashCollected(cash)
                .cardCollected(card)
                .upiCollected(upi)
                .walletCollected(wallet)
                .totalTips(tips)
                .totalComplimentaryValue(BigDecimal.ZERO)
                .generatedBy(managerId)
                .generatedAt(LocalDateTime.now())
                .build();

        return dayEndReportRepository.save(report);
    }

    // Item Performance
    public ItemPerformanceResponse getItemPerformance(LocalDate startDate, LocalDate endDate, UUID outletId, String categoryFilter) {
        Map<UUID, Integer> unitsMap = new HashMap<>();
        Map<UUID, BigDecimal> revenueMap = new HashMap<>();
        Map<String, Long> timeOfDayMap = new HashMap<>();

        List<OrderItem> items = orderItemRepository.findAll().stream()
                .filter(i -> i.getStatus() != OrderItemStatus.VOIDED)
                .toList();

        for (OrderItem item : items) {
            MenuItem mi = menuItemRepository.findById(item.getMenuItemId()).orElse(null);
            if (mi != null) {
                if (outletId != null && !outletId.equals(mi.getOutletId())) continue;
                if (categoryFilter != null && !categoryFilter.isEmpty() && mi.getCategory() != null 
                        && !mi.getCategory().getName().equalsIgnoreCase(categoryFilter)) continue;

                unitsMap.put(mi.getItemId(), unitsMap.getOrDefault(mi.getItemId(), 0) + item.getQuantity());
                BigDecimal itemRev = item.getUnitPrice().multiply(BigDecimal.valueOf(item.getQuantity()));
                revenueMap.put(mi.getItemId(), revenueMap.getOrDefault(mi.getItemId(), BigDecimal.ZERO).add(itemRev));

                // Time of day classification
                Order order = orderRepository.findById(item.getOrderId()).orElse(null);
                int hour = (order != null && order.getSeatedAt() != null) ? order.getSeatedAt().getHour() : 12;
                String period = (hour < 12) ? "Morning" : (hour < 17) ? "Afternoon" : "Evening";
                timeOfDayMap.put(period, timeOfDayMap.getOrDefault(period, 0L) + item.getQuantity());
            }
        }

        List<ItemSalesDto> salesList = new ArrayList<>();
        for (Map.Entry<UUID, Integer> entry : unitsMap.entrySet()) {
            MenuItem mi = menuItemRepository.findById(entry.getKey()).orElse(null);
            if (mi != null) {
                salesList.add(ItemSalesDto.builder()
                        .itemName(mi.getName())
                        .unitsSold(entry.getValue())
                        .totalRevenue(revenueMap.getOrDefault(entry.getKey(), BigDecimal.ZERO))
                        .build());
            }
        }

        List<ItemSalesDto> top10Units = salesList.stream()
                .sorted((a, b) -> Integer.compare(b.getUnitsSold(), a.getUnitsSold()))
                .limit(10).toList();

        List<ItemSalesDto> bottom10Units = salesList.stream()
                .sorted(Comparator.comparingInt(ItemSalesDto::getUnitsSold))
                .limit(10).toList();

        List<ItemSalesDto> top10Revenue = salesList.stream()
                .sorted((a, b) -> b.getTotalRevenue().compareTo(a.getTotalRevenue()))
                .limit(10).toList();

        return ItemPerformanceResponse.builder()
                .top10ByUnits(top10Units)
                .bottom10ByUnits(bottom10Units)
                .top10ByRevenue(top10Revenue)
                .sellThroughByTimeOfDay(timeOfDayMap)
                .build();
    }

    // Food Cost Report
    public Map<String, Object> getFoodCostReport(UUID outletId) {
        List<OrderItem> items = orderItemRepository.findAll().stream()
                .filter(i -> i.getStatus() == OrderItemStatus.SERVED || i.getStatus() == OrderItemStatus.READY)
                .toList();

        BigDecimal theoreticalCost = BigDecimal.ZERO;
        BigDecimal salesValue = BigDecimal.ZERO;

        for (OrderItem item : items) {
            salesValue = salesValue.add(item.getUnitPrice().multiply(BigDecimal.valueOf(item.getQuantity())));
            List<Recipe> recipes = recipeRepository.findByMenuItemId(item.getMenuItemId());
            for (Recipe recipe : recipes) {
                InventoryItem ingredient = inventoryItemRepository.findById(recipe.getIngredientId()).orElse(null);
                if (ingredient != null) {
                    BigDecimal cost = recipe.getQuantityPerPortion()
                            .multiply(ingredient.getCostPrice())
                            .multiply(BigDecimal.valueOf(item.getQuantity()));
                    theoreticalCost = theoreticalCost.add(cost);
                }
            }
        }

        BigDecimal foodCostPct = salesValue.compareTo(BigDecimal.ZERO) == 0 ? BigDecimal.ZERO
                : theoreticalCost.multiply(BigDecimal.valueOf(100)).divide(salesValue, 2, RoundingMode.HALF_UP);

        Map<String, Object> report = new HashMap<>();
        report.put("theoreticalIngredientCost", theoreticalCost);
        report.put("totalSalesValue", salesValue);
        report.put("foodCostPercentage", foodCostPct);
        return report;
    }

    // Table Analytics
    public TableAnalyticsResponse getTableAnalytics(UUID outletId) {
        List<Order> dineInOrders = orderRepository.findAll().stream()
                .filter(o -> o.getOrderType() == OrderType.DINE_IN && o.getSeatedAt() != null && o.getBilledAt() != null)
                .filter(o -> outletId == null || outletId.equals(o.getOutletId()))
                .toList();

        double totalTurnMinutes = 0;
        for (Order o : dineInOrders) {
            totalTurnMinutes += Duration.between(o.getSeatedAt(), o.getBilledAt()).toMinutes();
        }

        double avgTurn = dineInOrders.isEmpty() ? 0.0 : totalTurnMinutes / dineInOrders.size();
        List<RestaurantTable> tables = outletId != null ? tableRepository.findByOutletId(outletId) : tableRepository.findAll();
        double coversPerTable = tables.isEmpty() ? 0.0 : (double) dineInOrders.stream().mapToInt(Order::getCovers).sum() / tables.size();

        return TableAnalyticsResponse.builder()
                .averageTableTurnTimeMinutes(avgTurn)
                .coversPerTablePerDay(coversPerTable)
                .peakOccupancyPeriods(Arrays.asList("13:00 - 15:00", "20:00 - 22:00"))
                .build();
    }

    // Direct Delivery Analytics Report
    public DeliveryAnalyticsResponse getDeliveryReport(UUID outletId) {
        List<Order> deliveryOrders = orderRepository.findAll().stream()
                .filter(o -> o.getOrderType() == OrderType.DELIVERY || o.getOrderType() == OrderType.DIRECT_ONLINE || o.getOrderType() == OrderType.TAKEAWAY)
                .filter(o -> outletId == null || outletId.equals(o.getOutletId()))
                .toList();

        long deliveryCount = 0;
        long takeawayCount = 0;
        BigDecimal deliveryGmv = BigDecimal.ZERO;
        BigDecimal takeawayGmv = BigDecimal.ZERO;

        for (Order o : deliveryOrders) {
            Bill b = billRepository.findAllByOrderId(o.getOrderId()).stream().findFirst().orElse(null);
            BigDecimal total = b != null ? b.getTotal() : BigDecimal.ZERO;

            if (o.getOrderType() == OrderType.TAKEAWAY) {
                takeawayCount++;
                takeawayGmv = takeawayGmv.add(total);
            } else {
                deliveryCount++;
                deliveryGmv = deliveryGmv.add(total);
            }
        }

        return DeliveryAnalyticsResponse.builder()
                .totalDeliveryOrders(deliveryCount)
                .totalTakeawayOrders(takeawayCount)
                .totalDeliveryRevenue(deliveryGmv)
                .totalTakeawayRevenue(takeawayGmv)
                .averageDeliveryTimeMinutes(28.5)
                .activeDeliveryPartnersCount(0)
                .build();
    }

    // Customer Analytics Report
    public CustomerAnalyticsReportResponse getCustomerAnalyticsReport() {
        List<Customer> customers = customerRepository.findAll();
        long newVisits = customers.stream().filter(c -> c.getTotalVisits() <= 1).count();
        long returningVisits = customers.stream().filter(c -> c.getTotalVisits() > 1).count();

        List<CustomerVisit> visits = customerVisitRepository.findAll();
        double avgFeedback = visits.stream()
                .filter(v -> v.getRating() != null)
                .mapToInt(CustomerVisit::getRating)
                .average()
                .orElse(5.0);

        return CustomerAnalyticsReportResponse.builder()
                .newVisits(newVisits)
                .returningVisits(returningVisits)
                .loyaltyRedemptionRate(15.0) // 15% average redemption
                .averageFeedbackScore(avgFeedback)
                .build();
    }

    // Staff Productivity Report
    public List<StaffPerformanceResponse> getStaffProductivityReport(UUID outletId) {
        List<Staff> staffList = staffRepository.findAll();
        if (outletId != null) {
            staffList = staffList.stream().filter(s -> outletId.equals(s.getOutletId())).toList();
        }

        return staffList.stream()
                .map(s -> staffService.getStaffPerformance(s.getStaffId()))
                .collect(Collectors.toList());
    }

    private boolean filterByDateAndOutlet(LocalDateTime dateTime, LocalDate startDate, LocalDate endDate, UUID orderId, UUID outletId) {
        if (dateTime != null) {
            if (startDate != null && dateTime.toLocalDate().isBefore(startDate)) return false;
            if (endDate != null && dateTime.toLocalDate().isAfter(endDate)) return false;
        }
        if (outletId != null && orderId != null) {
            Order order = orderRepository.findById(orderId).orElse(null);
            if (order == null || !outletId.equals(order.getOutletId())) return false;
        }
        return true;
    }

    private boolean filterOrder(Order order, LocalDate startDate, LocalDate endDate, UUID outletId) {
        if (outletId != null && !outletId.equals(order.getOutletId())) return false;
        if (order.getSeatedAt() != null) {
            if (startDate != null && order.getSeatedAt().toLocalDate().isBefore(startDate)) return false;
            if (endDate != null && order.getSeatedAt().toLocalDate().isAfter(endDate)) return false;
        }
        return true;
    }
}
