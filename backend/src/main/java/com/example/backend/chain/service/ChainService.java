package com.example.backend.chain.service;

import com.example.backend.bill.entity.Bill;
import com.example.backend.bill.repository.BillRepository;
import com.example.backend.chain.dto.*;
import com.example.backend.chain.entity.*;
import com.example.backend.chain.repository.*;
import com.example.backend.menu.entity.MenuItem;
import com.example.backend.menu.repository.MenuItemRepository;
import com.example.backend.order.entity.Order;
import com.example.backend.order.entity.OrderItem;
import com.example.backend.order.entity.OrderStatus;
import com.example.backend.order.repository.OrderItemRepository;
import com.example.backend.order.repository.OrderRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class ChainService {

    private final BrandRepository brandRepository;
    private final OutletRepository outletRepository;
    private final OutletMenuOverrideRepository overrideRepository;
    private final BrandPromotionRepository promotionRepository;
    private final CorporateNotificationRepository notificationRepository;
    private final MenuItemRepository menuItemRepository;
    private final OrderRepository orderRepository;
    private final OrderItemRepository orderItemRepository;
    private final BillRepository billRepository;

    public ChainService(BrandRepository brandRepository,
                        OutletRepository outletRepository,
                        OutletMenuOverrideRepository overrideRepository,
                        BrandPromotionRepository promotionRepository,
                        CorporateNotificationRepository notificationRepository,
                        MenuItemRepository menuItemRepository,
                        OrderRepository orderRepository,
                        OrderItemRepository orderItemRepository,
                        BillRepository billRepository) {
        this.brandRepository = brandRepository;
        this.outletRepository = outletRepository;
        this.overrideRepository = overrideRepository;
        this.promotionRepository = promotionRepository;
        this.notificationRepository = notificationRepository;
        this.menuItemRepository = menuItemRepository;
        this.orderRepository = orderRepository;
        this.orderItemRepository = orderItemRepository;
        this.billRepository = billRepository;
    }

    // Brand & Outlet setup
    @Transactional
    public Brand createBrand(Brand brand) {
        return brandRepository.save(brand);
    }

    @Transactional
    public Outlet createOutlet(Outlet outlet) {
        if (outlet.getBrandId() == null) {
            List<Brand> brands = brandRepository.findAll();
            if (!brands.isEmpty()) {
                outlet.setBrandId(brands.get(0).getId());
            } else {
                Brand defaultBrand = brandRepository.save(Brand.builder().name("Spice Haven Chain").build());
                outlet.setBrandId(defaultBrand.getId());
            }
        }
        return outletRepository.save(outlet);
    }

    public List<Outlet> getAllOutlets() {
        return outletRepository.findAll();
    }

    // Centralized menu pushing
    @Transactional
    public List<MenuItem> pushMenuToOutlets(PushMenuRequest request) {
        List<MenuItem> pushedItems = new ArrayList<>();
        List<MenuItem> sourceItems = menuItemRepository.findAllById(request.getMenuItemIds());

        for (UUID outletId : request.getTargetOutletIds()) {
            for (MenuItem item : sourceItems) {
                MenuItem outletItem = MenuItem.builder()
                        .outletId(outletId)
                        .name(item.getName())
                        .description(item.getDescription())
                        .price(item.getPrice())
                        .priceTakeaway(item.getPriceTakeaway())
                        .priceDelivery(item.getPriceDelivery())
                        .gstRate(item.getGstRate())
                        .foodType(item.getFoodType())
                        .isAvailable(item.isAvailable())
                        .isSpecial(item.isSpecial())
                        .specialPrice(item.getSpecialPrice())
                        .isVeg(item.isVeg())
                        .category(item.getCategory())
                        .stationId(item.getStationId())
                        .build();

                pushedItems.add(menuItemRepository.save(outletItem));
            }
        }

        System.out.println(String.format("[CENTRAL MENU PUSH] Pushed %d menu items to %d outlets.",
                sourceItems.size(), request.getTargetOutletIds().size()));

        return pushedItems;
    }

    // Outlet-specific overrides
    @Transactional
    public OutletMenuOverride saveOutletOverride(OverrideMenuRequest request) {
        OutletMenuOverride override = overrideRepository.findByOutletIdAndMenuItemId(request.getOutletId(), request.getMenuItemId())
                .orElseGet(() -> OutletMenuOverride.builder()
                        .outletId(request.getOutletId())
                        .menuItemId(request.getMenuItemId())
                        .build());

        if (request.getOverridePrice() != null) override.setOverridePrice(request.getOverridePrice());
        if (request.getIsAvailable() != null) override.setIsAvailable(request.getIsAvailable());
        if (request.getIsSpecial() != null) override.setIsSpecial(request.getIsSpecial());
        if (request.getSpecialPrice() != null) override.setSpecialPrice(request.getSpecialPrice());

        return overrideRepository.save(override);
    }

    // Chain-wide item unavailability broadcast
    @Transactional
    public void broadcastItemUnavailability(String menuItemName, boolean isAvailable) {
        List<MenuItem> items = menuItemRepository.findAll().stream()
                .filter(mi -> mi.getName().equalsIgnoreCase(menuItemName))
                .toList();

        for (MenuItem item : items) {
            item.setAvailable(isAvailable);
            menuItemRepository.save(item);
        }

        String statusStr = isAvailable ? "AVAILABLE" : "UNAVAILABLE (86'd)";
        System.out.println(String.format("[CHAIN-WIDE BROADCAST] Corporate marked item '%s' as %s across all %d outlet menu records.",
                menuItemName, statusStr, items.size()));
    }

    // Brand promotions
    @Transactional
    public List<BrandPromotion> getAllPromotions() {
        return promotionRepository.findAll();
    }

    // Brand promotions
    @Transactional
    public BrandPromotion createBrandPromotion(BrandPromotion promotion) {
        if (promotion.getBrandId() == null) {
            List<Brand> brands = brandRepository.findAll();
            if (brands.isEmpty()) {
                Brand defaultBrand = brandRepository.save(Brand.builder()
                        .name("Spice Haven Corporate")
                        .headquartersAddress("Main HQ")
                        .corporateContact("contact@spicehaven.com")
                        .build());
                promotion.setBrandId(defaultBrand.getId());
            } else {
                promotion.setBrandId(brands.get(0).getId());
            }
        }
        BrandPromotion saved = promotionRepository.save(promotion);
        System.out.println(String.format("[BRAND PROMOTION] Promo '%s' (%s%% OFF) launched across all chain outlets.",
                saved.getPromoCode(), saved.getDiscountPercentage()));
        return saved;
    }

    // Mystery Audit mode
    @Transactional
    public Outlet toggleMysteryAudit(UUID outletId, boolean active) {
        Outlet outlet = outletRepository.findById(outletId)
                .orElseThrow(() -> new RuntimeException("Outlet not found"));
        outlet.setMysteryAuditActive(active);
        Outlet saved = outletRepository.save(outlet);

        System.out.println(String.format("[MYSTERY AUDIT] Audit mode for outlet '%s' set to: %b (Invisible to outlet staff).",
                saved.getName(), active));
        return saved;
    }

    // Corporate notification broadcast
    @Transactional
    public CorporateNotification broadcastCorporateNotification(UUID brandId, String title, String message) {
        CorporateNotification notification = CorporateNotification.builder()
                .brandId(brandId != null ? brandId : UUID.randomUUID())
                .title(title)
                .message(message)
                .sentAt(LocalDateTime.now())
                .build();

        CorporateNotification saved = notificationRepository.save(notification);

        System.out.println(String.format("[CORPORATE BROADCAST ALERT] Sent alert '%s' to all outlet managers: \"%s\"",
                title, message));

        return saved;
    }

    // Franchise Royalty Calculation
    public BigDecimal calculateFranchiseRoyalty(UUID outletId) {
        Outlet outlet = outletRepository.findById(outletId)
                .orElseThrow(() -> new RuntimeException("Outlet not found"));

        if (!outlet.getIsFranchise()) {
            return BigDecimal.ZERO;
        }

        List<Bill> outletBills = billRepository.findAll().stream()
                .filter(b -> b.isSettled())
                .filter(b -> {
                    Order order = orderRepository.findById(b.getOrderId()).orElse(null);
                    return order != null && outletId.equals(order.getOutletId());
                })
                .toList();

        BigDecimal gmv = BigDecimal.ZERO;
        for (Bill b : outletBills) {
            gmv = gmv.add(b.getTotal());
        }

        BigDecimal royaltyRate = outlet.getRoyaltyPercentage() != null ? outlet.getRoyaltyPercentage() : BigDecimal.valueOf(5.00);
        return gmv.multiply(royaltyRate).divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
    }

    // Consolidated Chain Reporting
    public ConsolidatedChainReportResponse getConsolidatedChainReport() {
        List<Bill> allSettledBills = billRepository.findAll().stream()
                .filter(Bill::isSettled)
                .toList();

        BigDecimal totalGmv = BigDecimal.ZERO;
        for (Bill b : allSettledBills) {
            totalGmv = totalGmv.add(b.getTotal());
        }

        List<Order> allOrders = orderRepository.findAll().stream()
                .filter(o -> o.getStatus() == OrderStatus.PAID)
                .toList();

        long totalOrders = allOrders.size();
        int totalCovers = allOrders.stream().mapToInt(Order::getCovers).sum();

        BigDecimal aov = BigDecimal.ZERO;
        if (totalOrders > 0) {
            aov = totalGmv.divide(BigDecimal.valueOf(totalOrders), 2, RoundingMode.HALF_UP);
        }

        // Top selling items aggregation
        Map<String, Integer> itemSales = new HashMap<>();
        List<OrderItem> allItems = orderItemRepository.findAll();
        for (OrderItem item : allItems) {
            if (item.getStatus() != com.example.backend.order.entity.OrderItemStatus.VOIDED) {
                MenuItem menuItem = menuItemRepository.findById(item.getMenuItemId()).orElse(null);
                if (menuItem != null) {
                    itemSales.put(menuItem.getName(), itemSales.getOrDefault(menuItem.getName(), 0) + item.getQuantity());
                }
            }
        }

        List<String> topSelling = itemSales.entrySet().stream()
                .sorted((e1, e2) -> Integer.compare(e2.getValue(), e1.getValue()))
                .limit(5)
                .map(Map.Entry::getKey)
                .collect(Collectors.toList());

        return ConsolidatedChainReportResponse.builder()
                .chainTotalGmv(totalGmv)
                .chainTotalCovers(totalCovers)
                .chainTotalOrders(totalOrders)
                .chainAverageOrderValue(aov)
                .topSellingItems(topSelling)
                .build();
    }

    // Side-by-side outlet comparison benchmarking
    public List<OutletComparisonResponse> getOutletComparisons() {
        List<Outlet> outlets = outletRepository.findAll();
        List<OutletComparisonResponse> responses = new ArrayList<>();

        for (Outlet outlet : outlets) {
            List<Order> outletOrders = orderRepository.findAll().stream()
                    .filter(o -> outlet.getOutletId().equals(o.getOutletId()) && o.getStatus() == OrderStatus.PAID)
                    .toList();

            long totalOrders = outletOrders.size();
            int totalCovers = outletOrders.stream().mapToInt(Order::getCovers).sum();

            List<Bill> outletBills = billRepository.findAll().stream()
                    .filter(Bill::isSettled)
                    .filter(b -> {
                        Order order = orderRepository.findById(b.getOrderId()).orElse(null);
                        return order != null && outlet.getOutletId().equals(order.getOutletId());
                    })
                    .toList();

            BigDecimal gmv = BigDecimal.ZERO;
            for (Bill b : outletBills) {
                gmv = gmv.add(b.getTotal());
            }

            BigDecimal aov = BigDecimal.ZERO;
            if (totalOrders > 0) {
                aov = gmv.divide(BigDecimal.valueOf(totalOrders), 2, RoundingMode.HALF_UP);
            }

            BigDecimal royalty = BigDecimal.ZERO;
            if (outlet.getIsFranchise() != null && outlet.getIsFranchise()) {
                BigDecimal rate = outlet.getRoyaltyPercentage() != null ? outlet.getRoyaltyPercentage() : BigDecimal.valueOf(5.00);
                royalty = gmv.multiply(rate).divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
            }

            responses.add(OutletComparisonResponse.builder()
                    .outletId(outlet.getOutletId())
                    .outletName(outlet.getName())
                    .city(outlet.getCity())
                    .isFranchise(outlet.getIsFranchise())
                    .gmv(gmv)
                    .totalCovers(totalCovers)
                    .totalOrders(totalOrders)
                    .averageOrderValue(aov)
                    .calculatedRoyalty(royalty)
                    .mysteryAuditActive(outlet.getMysteryAuditActive())
                    .build());
        }

        return responses;
    }
}
