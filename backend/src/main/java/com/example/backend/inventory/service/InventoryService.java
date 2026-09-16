package com.example.backend.inventory.service;

import com.example.backend.inventory.dto.*;
import com.example.backend.inventory.entity.*;
import com.example.backend.inventory.repository.*;
import com.example.backend.menu.entity.ComboComponent;
import com.example.backend.menu.entity.MenuItem;
import com.example.backend.menu.repository.ComboComponentRepository;
import com.example.backend.menu.repository.MenuItemRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;

@Service
public class InventoryService {

    private final InventoryItemRepository inventoryItemRepository;
    private final RecipeRepository recipeRepository;
    private final ComboComponentRepository comboComponentRepository;
    private final MenuItemRepository menuItemRepository;
    private final PerishableBatchRepository perishableBatchRepository;
    private final DailyStockSheetRepository dailyStockSheetRepository;
    private final PurchaseOrderRepository purchaseOrderRepository;
    private final PurchaseOrderItemRepository purchaseOrderItemRepository;
    private final SupplierRepository supplierRepository;

    public InventoryService(InventoryItemRepository inventoryItemRepository,
                            RecipeRepository recipeRepository,
                            ComboComponentRepository comboComponentRepository,
                            MenuItemRepository menuItemRepository,
                            PerishableBatchRepository perishableBatchRepository,
                            DailyStockSheetRepository dailyStockSheetRepository,
                            PurchaseOrderRepository purchaseOrderRepository,
                            PurchaseOrderItemRepository purchaseOrderItemRepository,
                            SupplierRepository supplierRepository) {
        this.inventoryItemRepository = inventoryItemRepository;
        this.recipeRepository = recipeRepository;
        this.comboComponentRepository = comboComponentRepository;
        this.menuItemRepository = menuItemRepository;
        this.perishableBatchRepository = perishableBatchRepository;
        this.dailyStockSheetRepository = dailyStockSheetRepository;
        this.purchaseOrderRepository = purchaseOrderRepository;
        this.purchaseOrderItemRepository = purchaseOrderItemRepository;
        this.supplierRepository = supplierRepository;
    }

    public List<InventoryItem> getAllInventory() {
        return inventoryItemRepository.findAll();
    }

    @Transactional
    public InventoryItem recordGRN(UUID ingredientId, BigDecimal quantityReceived, BigDecimal costPrice) {
        InventoryItem item = inventoryItemRepository.findById(ingredientId)
                .orElseThrow(() -> new RuntimeException("Ingredient not found in inventory"));

        item.setCurrentStock(item.getCurrentStock().add(quantityReceived));
        if (costPrice != null) {
            item.setCostPrice(costPrice);
        }
        item.setLastUpdatedAt(LocalDateTime.now());
        InventoryItem saved = inventoryItemRepository.save(item);

        // Record in daily stock sheet
        LocalDate today = LocalDate.now();
        DailyStockSheet sheet = dailyStockSheetRepository.findByIngredientIdAndStockDate(ingredientId, today)
                .orElseGet(() -> DailyStockSheet.builder()
                        .ingredientId(ingredientId)
                        .stockDate(today)
                        .openingStock(saved.getCurrentStock().subtract(quantityReceived))
                        .build());

        sheet.setReceivedStock(sheet.getReceivedStock().add(quantityReceived));
        sheet.setTheoreticalClosing(sheet.getOpeningStock().add(sheet.getReceivedStock()).subtract(sheet.getTheoreticalConsumption()));
        dailyStockSheetRepository.save(sheet);

        // Add to perishable batches (FIFO)
        PerishableBatch batch = PerishableBatch.builder()
                .ingredientId(ingredientId)
                .quantity(quantityReceived)
                .purchaseDate(today)
                .expiryDate(today.plusDays(7)) // Default 7 day expiry
                .build();
        perishableBatchRepository.save(batch);

        return saved;
    }

    public List<InventoryItem> getLowStockAlerts() {
        return inventoryItemRepository.findAll().stream()
                .filter(item -> item.getCurrentStock().compareTo(item.getReorderLevel()) <= 0)
                .toList();
    }

    @Transactional
    public void deductIngredientsForMenuItem(UUID menuItemId, int quantity) {
        MenuItem menuItem = menuItemRepository.findById(menuItemId)
                .orElseThrow(() -> new RuntimeException("Menu item not found: " + menuItemId));

        if (menuItem.isCombo()) {
            List<ComboComponent> components = comboComponentRepository.findByComboItemId(menuItemId);
            for (ComboComponent component : components) {
                deductIngredientsForMenuItem(component.getComponentItemId(), quantity * component.getQuantity());
            }
        } else {
            List<Recipe> recipes = recipeRepository.findByMenuItemId(menuItemId);
            for (Recipe recipe : recipes) {
                InventoryItem ingredient = inventoryItemRepository.findById(recipe.getIngredientId())
                        .orElseThrow(() -> new RuntimeException("Ingredient not found: " + recipe.getIngredientId()));

                BigDecimal quantityToDeduct = recipe.getQuantityPerPortion().multiply(BigDecimal.valueOf(quantity));
                ingredient.setCurrentStock(ingredient.getCurrentStock().subtract(quantityToDeduct));
                ingredient.setLastUpdatedAt(LocalDateTime.now());
                InventoryItem saved = inventoryItemRepository.save(ingredient);

                // Check low stock and alert
                if (saved.getCurrentStock().compareTo(saved.getReorderLevel()) <= 0) {
                    System.out.println(String.format("[LOW STOCK ALERT] SMS/Email sent to manager: Ingredient '%s' has hit reorder level. Current Stock: %s %s. Reorder Level: %s %s.",
                            saved.getName(), saved.getCurrentStock(), saved.getUnit(), saved.getReorderLevel(), saved.getUnit()));
                }

                // Update Daily stock sheets
                LocalDate today = LocalDate.now();
                DailyStockSheet sheet = dailyStockSheetRepository.findByIngredientIdAndStockDate(recipe.getIngredientId(), today)
                        .orElseGet(() -> DailyStockSheet.builder()
                                .ingredientId(recipe.getIngredientId())
                                .stockDate(today)
                                .openingStock(saved.getCurrentStock().add(quantityToDeduct))
                                .build());

                sheet.setTheoreticalConsumption(sheet.getTheoreticalConsumption().add(quantityToDeduct));
                sheet.setTheoreticalClosing(sheet.getOpeningStock().add(sheet.getReceivedStock()).subtract(sheet.getTheoreticalConsumption()));
                dailyStockSheetRepository.save(sheet);

                // Deduct from perishable batches (FIFO)
                List<PerishableBatch> batches = perishableBatchRepository.findByIngredientIdOrderByPurchaseDateAsc(recipe.getIngredientId());
                BigDecimal remainingDeduct = quantityToDeduct;
                for (PerishableBatch batch : batches) {
                    if (remainingDeduct.compareTo(BigDecimal.ZERO) <= 0) break;

                    if (batch.getQuantity().compareTo(remainingDeduct) <= 0) {
                        remainingDeduct = remainingDeduct.subtract(batch.getQuantity());
                        perishableBatchRepository.delete(batch);
                    } else {
                        batch.setQuantity(batch.getQuantity().subtract(remainingDeduct));
                        perishableBatchRepository.save(batch);
                        remainingDeduct = BigDecimal.ZERO;
                    }
                }
            }
        }
    }

    @Transactional
    public void restoreIngredientsForMenuItem(UUID menuItemId, int quantity) {
        MenuItem menuItem = menuItemRepository.findById(menuItemId)
                .orElseThrow(() -> new RuntimeException("Menu item not found: " + menuItemId));

        if (menuItem.isCombo()) {
            List<ComboComponent> components = comboComponentRepository.findByComboItemId(menuItemId);
            for (ComboComponent component : components) {
                restoreIngredientsForMenuItem(component.getComponentItemId(), quantity * component.getQuantity());
            }
        } else {
            List<Recipe> recipes = recipeRepository.findByMenuItemId(menuItemId);
            for (Recipe recipe : recipes) {
                InventoryItem ingredient = inventoryItemRepository.findById(recipe.getIngredientId())
                        .orElseThrow(() -> new RuntimeException("Ingredient not found: " + recipe.getIngredientId()));

                BigDecimal quantityToRestore = recipe.getQuantityPerPortion().multiply(BigDecimal.valueOf(quantity));
                ingredient.setCurrentStock(ingredient.getCurrentStock().add(quantityToRestore));
                ingredient.setLastUpdatedAt(LocalDateTime.now());
                inventoryItemRepository.save(ingredient);

                // Update Daily stock sheets
                LocalDate today = LocalDate.now();
                DailyStockSheet sheet = dailyStockSheetRepository.findByIngredientIdAndStockDate(recipe.getIngredientId(), today)
                        .orElseGet(() -> DailyStockSheet.builder()
                                .ingredientId(recipe.getIngredientId())
                                .stockDate(today)
                                .openingStock(ingredient.getCurrentStock().subtract(quantityToRestore))
                                .build());

                sheet.setTheoreticalConsumption(sheet.getTheoreticalConsumption().subtract(quantityToRestore));
                if (sheet.getTheoreticalConsumption().compareTo(BigDecimal.ZERO) < 0) {
                    sheet.setTheoreticalConsumption(BigDecimal.ZERO);
                }
                sheet.setTheoreticalClosing(sheet.getOpeningStock().add(sheet.getReceivedStock()).subtract(sheet.getTheoreticalConsumption()));
                dailyStockSheetRepository.save(sheet);

                // Restore batch
                PerishableBatch batch = PerishableBatch.builder()
                        .ingredientId(recipe.getIngredientId())
                        .quantity(quantityToRestore)
                        .purchaseDate(today)
                        .expiryDate(today.plusDays(7))
                        .build();
                perishableBatchRepository.save(batch);
            }
        }
    }

    @Transactional
    public List<DailyStockSheet> setupDailyOpeningStock(List<DailyStockSetupRequest> requests) {
        LocalDate today = LocalDate.now();
        List<DailyStockSheet> sheets = new ArrayList<>();

        for (DailyStockSetupRequest req : requests) {
            DailyStockSheet sheet = dailyStockSheetRepository.findByIngredientIdAndStockDate(req.getIngredientId(), today)
                    .orElseGet(() -> DailyStockSheet.builder()
                            .ingredientId(req.getIngredientId())
                            .stockDate(today)
                            .build());

            sheet.setOpeningStock(req.getOpeningStock());
            sheet.setTheoreticalClosing(req.getOpeningStock().add(sheet.getReceivedStock()).subtract(sheet.getTheoreticalConsumption()));
            sheets.add(dailyStockSheetRepository.save(sheet));
        }

        return sheets;
    }

    @Transactional
    public List<DailyStockSheet> registerClosingStock(List<DailyStockCloseRequest> requests) {
        LocalDate today = LocalDate.now();
        List<DailyStockSheet> sheets = new ArrayList<>();

        for (DailyStockCloseRequest req : requests) {
            DailyStockSheet sheet = dailyStockSheetRepository.findByIngredientIdAndStockDate(req.getIngredientId(), today)
                    .orElseThrow(() -> new RuntimeException("Daily stock sheet not found for today. Set opening stock first."));

            sheet.setActualClosing(req.getActualClosing());
            sheet.setVariance(req.getActualClosing().subtract(sheet.getTheoreticalClosing()));
            sheets.add(dailyStockSheetRepository.save(sheet));
        }

        return sheets;
    }

    @Transactional
    public PurchaseOrder raisePurchaseOrder(PurchaseOrderRequest request) {
        BigDecimal totalValue = BigDecimal.ZERO;
        for (PurchaseOrderItemRequest item : request.getItems()) {
            totalValue = totalValue.add(item.getQuantity().multiply(item.getUnitPrice()));
        }

        PurchaseOrder po = PurchaseOrder.builder()
                .outletId(UUID.randomUUID())
                .supplierId(request.getSupplierId())
                .status(PurchaseOrderStatus.SENT)
                .totalValue(totalValue)
                .raisedAt(LocalDateTime.now())
                .expectedDelivery(request.getExpectedDelivery())
                .build();

        PurchaseOrder savedPo = purchaseOrderRepository.save(po);

        for (PurchaseOrderItemRequest item : request.getItems()) {
            PurchaseOrderItem poi = PurchaseOrderItem.builder()
                    .poId(savedPo.getPoId())
                    .ingredientId(item.getIngredientId())
                    .quantity(item.getQuantity())
                    .unitPrice(item.getUnitPrice())
                    .build();
            purchaseOrderItemRepository.save(poi);
        }

        return savedPo;
    }

    @Transactional
    public PurchaseOrder receivePurchaseOrderGRN(UUID poId) {
        PurchaseOrder po = purchaseOrderRepository.findById(poId)
                .orElseThrow(() -> new RuntimeException("Purchase order not found: " + poId));

        if (po.getStatus() != PurchaseOrderStatus.SENT) {
            throw new RuntimeException("Purchase order is already completed/cancelled");
        }

        po.setStatus(PurchaseOrderStatus.RECEIVED);
        PurchaseOrder savedPo = purchaseOrderRepository.save(po);

        List<PurchaseOrderItem> items = purchaseOrderItemRepository.findByPoId(poId);
        for (PurchaseOrderItem item : items) {
            recordGRN(item.getIngredientId(), item.getQuantity(), item.getUnitPrice());
        }

        return savedPo;
    }

    public List<CogsReportResponse> getCogsReport() {
        List<MenuItem> menuItems = menuItemRepository.findAll();
        List<CogsReportResponse> responses = new ArrayList<>();

        for (MenuItem item : menuItems) {
            BigDecimal cogs = calculateMenuItemCogs(item.getItemId());
            BigDecimal price = item.getPrice();
            BigDecimal grossMargin = BigDecimal.ZERO;
            if (price.compareTo(BigDecimal.ZERO) > 0) {
                grossMargin = price.subtract(cogs).multiply(BigDecimal.valueOf(100)).divide(price, 2, RoundingMode.HALF_UP);
            }

            responses.add(CogsReportResponse.builder()
                    .menuItemId(item.getItemId())
                    .menuItemName(item.getName())
                    .menuItemPrice(price)
                    .ingredientCost(cogs)
                    .grossMarginPercentage(grossMargin)
                    .build());
        }

        return responses;
    }

    private BigDecimal calculateMenuItemCogs(UUID menuItemId) {
        MenuItem menuItem = menuItemRepository.findById(menuItemId).orElse(null);
        if (menuItem == null) return BigDecimal.ZERO;

        if (menuItem.isCombo()) {
            BigDecimal comboCogs = BigDecimal.ZERO;
            List<ComboComponent> components = comboComponentRepository.findByComboItemId(menuItemId);
            for (ComboComponent component : components) {
                comboCogs = comboCogs.add(calculateMenuItemCogs(component.getComponentItemId()).multiply(BigDecimal.valueOf(component.getQuantity())));
            }
            return comboCogs;
        } else {
            BigDecimal recipeCogs = BigDecimal.ZERO;
            List<Recipe> recipes = recipeRepository.findByMenuItemId(menuItemId);
            for (Recipe recipe : recipes) {
                InventoryItem ingredient = inventoryItemRepository.findById(recipe.getIngredientId()).orElse(null);
                if (ingredient != null) {
                    recipeCogs = recipeCogs.add(recipe.getQuantityPerPortion().multiply(ingredient.getCostPrice()));
                }
            }
            return recipeCogs;
        }
    }

    // Supplier Master CRUD
    @Transactional
    public Supplier createSupplier(SupplierRequest request) {
        Supplier supplier = Supplier.builder()
                .name(request.getName())
                .contact(request.getContact())
                .itemsSupplied(request.getItemsSupplied())
                .priceHistory(request.getPriceHistory())
                .build();
        return supplierRepository.save(supplier);
    }

    public List<Supplier> getAllSuppliers() {
        return supplierRepository.findAll();
    }

    // Expiry Batch Reports
    public List<PerishableBatch> getAllPerishableBatches() {
        return perishableBatchRepository.findAll();
    }
}
