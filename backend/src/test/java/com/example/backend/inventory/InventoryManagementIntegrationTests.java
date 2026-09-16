package com.example.backend.inventory;

import com.example.backend.inventory.dto.*;
import com.example.backend.inventory.entity.*;
import com.example.backend.inventory.repository.*;
import com.example.backend.inventory.service.InventoryService;
import com.example.backend.menu.entity.MenuItem;
import com.example.backend.menu.repository.MenuItemRepository;
import com.example.backend.order.entity.Order;
import com.example.backend.order.entity.OrderItem;
import com.example.backend.order.entity.OrderItemStatus;
import com.example.backend.order.entity.OrderType;
import com.example.backend.order.service.OrderService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Collections;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@Transactional
public class InventoryManagementIntegrationTests {

    @Autowired
    private InventoryService inventoryService;

    @Autowired
    private OrderService orderService;

    @Autowired
    private InventoryItemRepository inventoryRepository;

    @Autowired
    private RecipeRepository recipeRepository;

    @Autowired
    private MenuItemRepository menuItemRepository;

    @Autowired
    private SupplierRepository supplierRepository;

    @Autowired
    private PurchaseOrderRepository purchaseOrderRepository;

    @Autowired
    private PurchaseOrderItemRepository purchaseOrderItemRepository;

    @Autowired
    private DailyStockSheetRepository dailyStockSheetRepository;

    @Autowired
    private PerishableBatchRepository perishableBatchRepository;

    private UUID outletId;
    private MenuItem burger;
    private InventoryItem patty;
    private Supplier supplier;

    @BeforeEach
    public void setUp() {
        outletId = UUID.randomUUID();
        recipeRepository.deleteAll();
        inventoryRepository.deleteAll();
        menuItemRepository.deleteAll();
        supplierRepository.deleteAll();
        purchaseOrderRepository.deleteAll();
        purchaseOrderItemRepository.deleteAll();
        dailyStockSheetRepository.deleteAll();
        perishableBatchRepository.deleteAll();

        // 1. Seed Ingredient (Patty)
        patty = InventoryItem.builder()
                .outletId(outletId)
                .name("Burger Patty")
                .unit("nos")
                .currentStock(BigDecimal.valueOf(100.00))
                .reorderLevel(BigDecimal.valueOf(10.00))
                .costPrice(BigDecimal.valueOf(15.00))
                .build();
        patty = inventoryRepository.save(patty);

        // 2. Seed MenuItem (Burger)
        burger = MenuItem.builder()
                .outletId(outletId)
                .name("Veg Burger")
                .price(BigDecimal.valueOf(99.00))
                .gstRate(BigDecimal.valueOf(5.0))
                .foodType("Veg")
                .isAvailable(true)
                .build();
        burger = menuItemRepository.save(burger);

        // 3. Link recipe: 1 Veg Burger = 1 Burger Patty
        Recipe recipe = Recipe.builder()
                .menuItemId(burger.getItemId())
                .ingredientId(patty.getIngredientId())
                .quantityPerPortion(BigDecimal.valueOf(1.00))
                .unit("nos")
                .build();
        recipeRepository.save(recipe);

        // 4. Seed Supplier
        supplier = Supplier.builder()
                .name("Global Foods")
                .contact("9999888877")
                .itemsSupplied("Burger Patty")
                .priceHistory("Burger Patty: 15.00")
                .build();
        supplier = supplierRepository.save(supplier);
    }

    @Test
    public void testRecipeAutoDeductionOnKotAndAlert() {
        Order order = Order.builder()
                .outletId(outletId)
                .orderType(OrderType.TAKEAWAY)
                .build();

        OrderItem item = OrderItem.builder()
                .menuItemId(burger.getItemId())
                .quantity(2)
                .unitPrice(burger.getPrice())
                .status(OrderItemStatus.PENDING)
                .build();

        // Fire KOT -> should auto-deduct ingredients (2 Burger Patties)
        order = orderService.createOrder(order, Collections.singletonList(item));
        orderService.fireKot(order.getOrderId());

        InventoryItem updatedPatty = inventoryRepository.findById(patty.getIngredientId()).orElseThrow();
        // 100 - 2 = 98
        assertEquals(BigDecimal.valueOf(98.00).setScale(2), updatedPatty.getCurrentStock().setScale(2));

        // Verify Daily Stock Sheet records theoretical consumption
        DailyStockSheet sheet = dailyStockSheetRepository.findByIngredientIdAndStockDate(patty.getIngredientId(), LocalDate.now()).orElseThrow();
        assertEquals(BigDecimal.valueOf(2.00).setScale(2), sheet.getTheoreticalConsumption().setScale(2));
    }

    @Test
    public void testDailyStockVarianceAndWastageReport() {
        LocalDate today = LocalDate.now();

        // Setup opening stock
        DailyStockSetupRequest setup = DailyStockSetupRequest.builder()
                .ingredientId(patty.getIngredientId())
                .openingStock(BigDecimal.valueOf(100.00))
                .build();
        inventoryService.setupDailyOpeningStock(Collections.singletonList(setup));

        // Deduct stock via menu item consumption (e.g. 5 patties)
        inventoryService.deductIngredientsForMenuItem(burger.getItemId(), 5);

        // Register actual closing stock (93 instead of theoretical 95)
        DailyStockCloseRequest close = DailyStockCloseRequest.builder()
                .ingredientId(patty.getIngredientId())
                .actualClosing(BigDecimal.valueOf(93.00))
                .build();
        List<DailyStockSheet> closedSheets = inventoryService.registerClosingStock(Collections.singletonList(close));
        assertEquals(1, closedSheets.size());

        DailyStockSheet sheet = closedSheets.get(0);
        // Variance = 93.00 - 95.00 = -2.00
        assertEquals(BigDecimal.valueOf(-2.00).setScale(2), sheet.getVariance().setScale(2));
    }

    @Test
    public void testPurchaseOrderAndGRNReceipt() {
        // Raise PO
        PurchaseOrderItemRequest itemRequest = PurchaseOrderItemRequest.builder()
                .ingredientId(patty.getIngredientId())
                .quantity(BigDecimal.valueOf(50.00))
                .unitPrice(BigDecimal.valueOf(14.50))
                .build();

        PurchaseOrderRequest poRequest = PurchaseOrderRequest.builder()
                .supplierId(supplier.getSupplierId())
                .expectedDelivery(LocalDate.now().plusDays(2))
                .items(Collections.singletonList(itemRequest))
                .build();

        PurchaseOrder po = inventoryService.raisePurchaseOrder(poRequest);
        assertEquals(PurchaseOrderStatus.SENT, po.getStatus());
        assertEquals(BigDecimal.valueOf(725.00).setScale(2), po.getTotalValue().setScale(2));

        // Receive PO (GRN receipt updates stock)
        PurchaseOrder received = inventoryService.receivePurchaseOrderGRN(po.getPoId());
        assertEquals(PurchaseOrderStatus.RECEIVED, received.getStatus());

        InventoryItem updatedPatty = inventoryRepository.findById(patty.getIngredientId()).orElseThrow();
        // 100 + 50 = 150
        assertEquals(BigDecimal.valueOf(150.00).setScale(2), updatedPatty.getCurrentStock().setScale(2));
    }

    @Test
    public void testFIFOPerishableBatchDeduction() {
        LocalDate today = LocalDate.now();

        // Seed perishable batches
        PerishableBatch batch1 = PerishableBatch.builder()
                .ingredientId(patty.getIngredientId())
                .quantity(BigDecimal.valueOf(10.00))
                .purchaseDate(today.minusDays(2))
                .build();
        perishableBatchRepository.save(batch1);

        PerishableBatch batch2 = PerishableBatch.builder()
                .ingredientId(patty.getIngredientId())
                .quantity(BigDecimal.valueOf(10.00))
                .purchaseDate(today.minusDays(1))
                .build();
        perishableBatchRepository.save(batch2);

        // Deduct 13.00 patties
        inventoryService.deductIngredientsForMenuItem(burger.getItemId(), 13);

        List<PerishableBatch> remainingBatches = perishableBatchRepository.findByIngredientIdOrderByPurchaseDateAsc(patty.getIngredientId());
        // Batch 1 (10.00) fully consumed, Batch 2 partially consumed: 10 - (13 - 10) = 7
        assertEquals(1, remainingBatches.size());
        assertEquals(BigDecimal.valueOf(7.00).setScale(2), remainingBatches.get(0).getQuantity().setScale(2));
    }

    @Test
    public void testCOGSAndGrossMarginReport() {
        List<CogsReportResponse> reports = inventoryService.getCogsReport();
        assertFalse(reports.isEmpty());

        CogsReportResponse report = reports.stream()
                .filter(r -> r.getMenuItemName().equals("Veg Burger"))
                .findFirst().orElseThrow();

        // Veg Burger price: 99.00, COGS: 15.00
        // Gross Margin = (99 - 15) / 99 * 100 = 84.85%
        assertEquals(BigDecimal.valueOf(15.00).setScale(2), report.getIngredientCost().setScale(2));
        assertEquals(BigDecimal.valueOf(84.85).setScale(2), report.getGrossMarginPercentage().setScale(2));
    }
}
