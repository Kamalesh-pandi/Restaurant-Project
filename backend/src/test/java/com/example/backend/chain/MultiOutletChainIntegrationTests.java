package com.example.backend.chain;

import com.example.backend.bill.entity.Bill;
import com.example.backend.bill.repository.BillRepository;
import com.example.backend.chain.dto.*;
import com.example.backend.chain.entity.*;
import com.example.backend.chain.repository.*;
import com.example.backend.chain.service.ChainService;
import com.example.backend.menu.entity.MenuItem;
import com.example.backend.menu.repository.MenuItemRepository;
import com.example.backend.order.entity.Order;
import com.example.backend.order.entity.OrderStatus;
import com.example.backend.order.entity.OrderType;
import com.example.backend.order.repository.OrderRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@Transactional
public class MultiOutletChainIntegrationTests {

    @Autowired
    private ChainService chainService;

    @Autowired
    private BrandRepository brandRepository;

    @Autowired
    private OutletRepository outletRepository;

    @Autowired
    private OutletMenuOverrideRepository overrideRepository;

    @Autowired
    private BrandPromotionRepository promotionRepository;

    @Autowired
    private CorporateNotificationRepository notificationRepository;

    @Autowired
    private MenuItemRepository menuItemRepository;

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private BillRepository billRepository;

    private Brand brand;
    private Outlet outlet1;
    private Outlet outlet2;
    private MenuItem pizzaMaster;

    @BeforeEach
    public void setUp() {
        notificationRepository.deleteAll();
        promotionRepository.deleteAll();
        overrideRepository.deleteAll();
        billRepository.deleteAll();
        orderRepository.deleteAll();
        menuItemRepository.deleteAll();
        outletRepository.deleteAll();
        brandRepository.deleteAll();

        // 1. Create Brand
        brand = Brand.builder()
                .name("Pizza Deluxe Corporate")
                .headquartersAddress("123 Tech Park, City")
                .corporateContact("corporate@pizzadeluxe.com")
                .build();
        brand = chainService.createBrand(brand);

        // 2. Create Outlets
        outlet1 = Outlet.builder()
                .brandId(brand.getId())
                .name("Downtown Branch")
                .city("Metro")
                .isFranchise(false)
                .mysteryAuditActive(false)
                .build();
        outlet1 = chainService.createOutlet(outlet1);

        outlet2 = Outlet.builder()
                .brandId(brand.getId())
                .name("Airport Franchise")
                .city("Metro")
                .isFranchise(true)
                .royaltyPercentage(BigDecimal.valueOf(6.00)) // 6% royalty
                .mysteryAuditActive(false)
                .build();
        outlet2 = chainService.createOutlet(outlet2);

        // 3. Create Master Menu Item
        pizzaMaster = MenuItem.builder()
                .outletId(outlet1.getOutletId())
                .name("Margherita Pizza")
                .price(BigDecimal.valueOf(300.00))
                .gstRate(BigDecimal.valueOf(5.0))
                .isAvailable(true)
                .foodType("Veg")
                .build();
        pizzaMaster = menuItemRepository.save(pizzaMaster);
    }

    @Test
    public void testCentralizedMenuPushAndOverrides() {
        PushMenuRequest pushReq = PushMenuRequest.builder()
                .targetOutletIds(Collections.singletonList(outlet2.getOutletId()))
                .menuItemIds(Collections.singletonList(pizzaMaster.getItemId()))
                .build();

        List<MenuItem> pushed = chainService.pushMenuToOutlets(pushReq);
        assertEquals(1, pushed.size());
        assertEquals(outlet2.getOutletId(), pushed.get(0).getOutletId());

        // Outlet-specific price override for Airport branch
        OverrideMenuRequest overrideReq = OverrideMenuRequest.builder()
                .outletId(outlet2.getOutletId())
                .menuItemId(pushed.get(0).getItemId())
                .overridePrice(BigDecimal.valueOf(350.00))
                .isAvailable(true)
                .build();

        OutletMenuOverride override = chainService.saveOutletOverride(overrideReq);
        assertEquals(BigDecimal.valueOf(350.00), override.getOverridePrice());
    }

    @Test
    public void testChainWideItemUnavailabilityBroadcast() {
        chainService.broadcastItemUnavailability("Margherita Pizza", false);

        MenuItem fetched = menuItemRepository.findById(pizzaMaster.getItemId()).orElseThrow();
        assertFalse(fetched.isAvailable());
    }

    @Test
    public void testBrandPromotionsAndMysteryAudit() {
        BrandPromotion promo = BrandPromotion.builder()
                .brandId(brand.getId())
                .promoCode("FESTIVE20")
                .discountPercentage(BigDecimal.valueOf(20.00))
                .description("Festive Season 20% Off")
                .validFrom(LocalDateTime.now())
                .validTo(LocalDateTime.now().plusDays(7))
                .isActive(true)
                .build();

        BrandPromotion saved = chainService.createBrandPromotion(promo);
        assertNotNull(saved.getId());
        assertEquals("FESTIVE20", saved.getPromoCode());

        // Enable Mystery Audit
        Outlet audited = chainService.toggleMysteryAudit(outlet1.getOutletId(), true);
        assertTrue(audited.getMysteryAuditActive());
    }

    @Test
    public void testCorporateNotificationAndFranchiseRoyalty() {
        CorporateNotification notif = chainService.broadcastCorporateNotification(brand.getId(), "Health Safety Check", "Mandatory audit tomorrow at 10 AM");
        assertNotNull(notif.getId());

        // Seed Paid Order and Bill for Outlet 2 (Franchise)
        Order order = Order.builder()
                .outletId(outlet2.getOutletId())
                .orderType(OrderType.DINE_IN)
                .status(OrderStatus.PAID)
                .covers(4)
                .build();
        order = orderRepository.save(order);

        Bill bill = Bill.builder()
                .orderId(order.getOrderId())
                .billNumber("BILL-000100")
                .subtotal(BigDecimal.valueOf(1000.00))
                .cgst(BigDecimal.ZERO)
                .sgst(BigDecimal.ZERO)
                .discount(BigDecimal.ZERO)
                .loyaltyDiscount(BigDecimal.ZERO)
                .roundOff(BigDecimal.ZERO)
                .total(BigDecimal.valueOf(1000.00))
                .isSettled(true)
                .createdAt(LocalDateTime.now())
                .build();
        billRepository.save(bill);

        // 6% of 1000.00 GMV = 60.00 royalty
        BigDecimal royalty = chainService.calculateFranchiseRoyalty(outlet2.getOutletId());
        assertEquals(BigDecimal.valueOf(60.00).setScale(2), royalty.setScale(2));
    }

    @Test
    public void testConsolidatedReportAndOutletComparison() {
        Order order1 = Order.builder()
                .outletId(outlet1.getOutletId())
                .orderType(OrderType.DINE_IN)
                .status(OrderStatus.PAID)
                .covers(2)
                .build();
        orderRepository.save(order1);

        Bill bill1 = Bill.builder()
                .orderId(order1.getOrderId())
                .billNumber("BILL-000101")
                .subtotal(BigDecimal.valueOf(500.00))
                .cgst(BigDecimal.ZERO)
                .sgst(BigDecimal.ZERO)
                .discount(BigDecimal.ZERO)
                .loyaltyDiscount(BigDecimal.ZERO)
                .roundOff(BigDecimal.ZERO)
                .total(BigDecimal.valueOf(500.00))
                .isSettled(true)
                .createdAt(LocalDateTime.now())
                .build();
        billRepository.save(bill1);

        ConsolidatedChainReportResponse report = chainService.getConsolidatedChainReport();
        assertEquals(BigDecimal.valueOf(500.00).setScale(2), report.getChainTotalGmv().setScale(2));
        assertEquals(2, report.getChainTotalCovers());
        assertEquals(1, report.getChainTotalOrders());

        List<OutletComparisonResponse> comparisons = chainService.getOutletComparisons();
        assertEquals(2, comparisons.size());
    }
}
