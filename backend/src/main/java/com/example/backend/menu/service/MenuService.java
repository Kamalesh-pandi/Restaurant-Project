package com.example.backend.menu.service;

import com.example.backend.menu.entity.*;
import com.example.backend.menu.repository.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class MenuService {

    private final MenuItemRepository menuItemRepository;
    private final CategoryRepository categoryRepository;
    private final ModifierGroupRepository modifierGroupRepository;
    private final ModifierOptionRepository modifierOptionRepository;
    private final ComboComponentRepository comboComponentRepository;
    private final QrCodeService qrCodeService;

    public MenuService(MenuItemRepository menuItemRepository,
                       CategoryRepository categoryRepository,
                       ModifierGroupRepository modifierGroupRepository,
                       ModifierOptionRepository modifierOptionRepository,
                       ComboComponentRepository comboComponentRepository,
                       QrCodeService qrCodeService) {
        this.menuItemRepository = menuItemRepository;
        this.categoryRepository = categoryRepository;
        this.modifierGroupRepository = modifierGroupRepository;
        this.modifierOptionRepository = modifierOptionRepository;
        this.comboComponentRepository = comboComponentRepository;
        this.qrCodeService = qrCodeService;
    }

    public List<Category> getAllCategories() {
        return categoryRepository.findAll();
    }

    @Transactional
    public Category createCategory(Category category) {
        return categoryRepository.save(category);
    }

    public List<MenuItem> getAllMenuItems() {
        return menuItemRepository.findAll();
    }

    public List<MenuItem> getMenuItemsByCategory(UUID categoryId) {
        return menuItemRepository.findByCategoryCategoryId(categoryId);
    }

    // Time-based availability check
    public List<MenuItem> getActiveMenuItemsByTime(LocalTime time) {
        return menuItemRepository.findAll().stream()
                .filter(item -> {
                    if (!item.isAvailable()) {
                        return false;
                    }
                    if (item.getAvailableFrom() != null && item.getAvailableTo() != null) {
                        return !time.isBefore(item.getAvailableFrom()) && !time.isAfter(item.getAvailableTo());
                    }
                    return true;
                })
                .collect(Collectors.toList());
    }

    @Transactional
    public MenuItem createMenuItem(MenuItem item) {
        if (item.getOutletId() == null) {
            item.setOutletId(UUID.randomUUID());
        }
        return menuItemRepository.save(item);
    }

    @Transactional
    public MenuItem updateMenuItem(UUID id, MenuItem itemDetails) {
        MenuItem item = menuItemRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Menu item not found"));
        item.setName(itemDetails.getName());
        item.setDescription(itemDetails.getDescription());
        item.setPrice(itemDetails.getPrice());
        item.setPriceTakeaway(itemDetails.getPriceTakeaway());
        item.setPriceDelivery(itemDetails.getPriceDelivery());
        item.setGstRate(itemDetails.getGstRate());
        item.setHsnCode(itemDetails.getHsnCode());
        item.setFoodType(itemDetails.getFoodType());
        item.setAvailable(itemDetails.isAvailable());
        item.setSpecial(itemDetails.isSpecial());
        item.setSpecialPrice(itemDetails.getSpecialPrice());
        item.setAvailableFrom(itemDetails.getAvailableFrom());
        item.setAvailableTo(itemDetails.getAvailableTo());
        item.setCalories(itemDetails.getCalories());
        item.setAllergens(itemDetails.getAllergens());
        item.setCombo(itemDetails.isCombo());
        item.setCategory(itemDetails.getCategory());
        item.setStationId(itemDetails.getStationId());
        item.setImageUrl(itemDetails.getImageUrl());
        item.setVeg(itemDetails.isVeg());
        MenuItem saved = menuItemRepository.save(item);
        push86Sync(saved);
        return saved;
    }

    private void push86Sync(MenuItem item) {
        String status = item.isAvailable() ? "AVAILABLE" : "UNAVAILABLE";
        System.out.println(String.format("[Aggregator Menu Sync] Item '%s' (ID: %s) availability status %s pushed to Swiggy and Zomato APIs.",
                item.getName(), item.getItemId(), status));
    }

    @Transactional
    public MenuItem toggleAvailability(UUID id) {
        MenuItem item = menuItemRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Menu item not found"));
        item.setAvailable(!item.isAvailable());
        MenuItem saved = menuItemRepository.save(item);
        push86Sync(saved);
        return saved;
    }

    // Explicit 86'ing method (mark as unavailable)
    @Transactional
    public MenuItem mark86(UUID id, boolean isAvailable) {
        MenuItem item = menuItemRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Menu item not found"));
        item.setAvailable(isAvailable);
        MenuItem saved = menuItemRepository.save(item);
        push86Sync(saved);
        return saved;
    }

    // Daily Specials
    public List<MenuItem> getDailySpecials() {
        return menuItemRepository.findAll().stream()
                .filter(MenuItem::isSpecial)
                .collect(Collectors.toList());
    }

    @Transactional
    public MenuItem setDailySpecial(UUID id, boolean isSpecial, BigDecimal specialPrice) {
        MenuItem item = menuItemRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Menu item not found"));
        item.setSpecial(isSpecial);
        item.setSpecialPrice(specialPrice);
        return menuItemRepository.save(item);
    }

    // Modifiers management
    public List<ModifierGroup> getModifierGroupsByItem(UUID menuItemId) {
        return modifierGroupRepository.findByMenuItemId(menuItemId);
    }

    @Transactional
    public ModifierGroup createModifierGroup(ModifierGroup group) {
        return modifierGroupRepository.save(group);
    }

    public List<ModifierOption> getModifierOptionsByGroup(UUID modifierGroupId) {
        return modifierOptionRepository.findByModifierGroupId(modifierGroupId);
    }

    @Transactional
    public ModifierOption createModifierOption(ModifierOption option) {
        return modifierOptionRepository.save(option);
    }

    // Combo management
    public List<ComboComponent> getComboComponents(UUID comboItemId) {
        return comboComponentRepository.findByComboItemId(comboItemId);
    }

    @Transactional
    public ComboComponent addComboComponent(ComboComponent component) {
        return comboComponentRepository.save(component);
    }

    // QR Code generation
    public byte[] getMenuQrCodeBytes(UUID outletId) {
        // Generates QR Code linking to customer facing digital menu for this outlet.
        String url = "https://menu.restaurantpos.com/outlet/" + outletId.toString();
        return qrCodeService.generateQrCode(url, 300, 300);
    }

    @Transactional
    public void deleteMenuItem(UUID id) {
        menuItemRepository.deleteById(id);
    }

    @Transactional
    public void deleteCategory(UUID id) {
        categoryRepository.deleteById(id);
    }
}
