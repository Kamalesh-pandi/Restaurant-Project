package com.example.backend.menu.controller;

import com.example.backend.menu.entity.*;
import com.example.backend.menu.service.MenuService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/menu")
public class MenuController {

    private final MenuService menuService;

    public MenuController(MenuService menuService) {
        this.menuService = menuService;
    }

    @GetMapping("/categories")
    public ResponseEntity<List<Category>> getAllCategories() {
        return ResponseEntity.ok(menuService.getAllCategories());
    }

    @PostMapping("/categories")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
    public ResponseEntity<Category> createCategory(@Valid @RequestBody Category category) {
        return ResponseEntity.status(HttpStatus.CREATED).body(menuService.createCategory(category));
    }

    @GetMapping("/items")
    public ResponseEntity<List<MenuItem>> getAllMenuItems() {
        return ResponseEntity.ok(menuService.getAllMenuItems());
    }

    @GetMapping("/items/category/{categoryId}")
    public ResponseEntity<List<MenuItem>> getMenuItemsByCategory(@PathVariable UUID categoryId) {
        return ResponseEntity.ok(menuService.getMenuItemsByCategory(categoryId));
    }

    // Time-based active menu items availability endpoint
    @GetMapping("/items/active")
    public ResponseEntity<List<MenuItem>> getActiveMenuItems(@RequestParam(required = false) String time) {
        LocalTime queryTime = time != null ? LocalTime.parse(time) : LocalTime.now();
        return ResponseEntity.ok(menuService.getActiveMenuItemsByTime(queryTime));
    }

    @PostMapping("/items")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
    public ResponseEntity<MenuItem> createMenuItem(@Valid @RequestBody MenuItem item) {
        return ResponseEntity.status(HttpStatus.CREATED).body(menuService.createMenuItem(item));
    }

    @PutMapping("/items/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
    public ResponseEntity<MenuItem> updateMenuItem(@PathVariable UUID id, @Valid @RequestBody MenuItem item) {
        return ResponseEntity.ok(menuService.updateMenuItem(id, item));
    }

    @PatchMapping("/items/{id}/toggle-availability")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
    public ResponseEntity<MenuItem> toggleAvailability(@PathVariable UUID id) {
        return ResponseEntity.ok(menuService.toggleAvailability(id));
    }

    // Explicit 86'ing endpoints
    @PatchMapping("/items/{id}/86")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER', 'KITCHEN')")
    public ResponseEntity<MenuItem> mark86Item(@PathVariable UUID id, @RequestParam boolean available) {
        return ResponseEntity.ok(menuService.mark86(id, available));
    }

    // Daily Specials endpoints
    @GetMapping("/items/specials")
    public ResponseEntity<List<MenuItem>> getDailySpecials() {
        return ResponseEntity.ok(menuService.getDailySpecials());
    }

    @PutMapping("/items/{id}/special")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
    public ResponseEntity<MenuItem> setDailySpecial(@PathVariable UUID id,
                                                    @RequestParam boolean special,
                                                    @RequestParam(required = false) BigDecimal specialPrice) {
        return ResponseEntity.ok(menuService.setDailySpecial(id, special, specialPrice));
    }

    // Modifiers endpoints
    @GetMapping("/items/{itemId}/modifier-groups")
    public ResponseEntity<List<ModifierGroup>> getModifierGroups(@PathVariable UUID itemId) {
        return ResponseEntity.ok(menuService.getModifierGroupsByItem(itemId));
    }

    @PostMapping("/modifier-groups")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
    public ResponseEntity<ModifierGroup> createModifierGroup(@Valid @RequestBody ModifierGroup group) {
        return ResponseEntity.status(HttpStatus.CREATED).body(menuService.createModifierGroup(group));
    }

    @GetMapping("/modifier-groups/{groupId}/options")
    public ResponseEntity<List<ModifierOption>> getModifierOptions(@PathVariable UUID groupId) {
        return ResponseEntity.ok(menuService.getModifierOptionsByGroup(groupId));
    }

    @PostMapping("/modifier-options")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
    public ResponseEntity<ModifierOption> createModifierOption(@Valid @RequestBody ModifierOption option) {
        return ResponseEntity.status(HttpStatus.CREATED).body(menuService.createModifierOption(option));
    }

    // Combos endpoints
    @GetMapping("/items/{comboItemId}/combo-components")
    public ResponseEntity<List<ComboComponent>> getComboComponents(@PathVariable UUID comboItemId) {
        return ResponseEntity.ok(menuService.getComboComponents(comboItemId));
    }

    @PostMapping("/combo-components")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
    public ResponseEntity<ComboComponent> addComboComponent(@Valid @RequestBody ComboComponent component) {
        return ResponseEntity.status(HttpStatus.CREATED).body(menuService.addComboComponent(component));
    }

    // Digital menu QR generation endpoint
    @GetMapping(value = "/outlets/{outletId}/qr", produces = MediaType.IMAGE_PNG_VALUE)
    public ResponseEntity<byte[]> getDigitalMenuQr(@PathVariable UUID outletId) {
        byte[] qrBytes = menuService.getMenuQrCodeBytes(outletId);
        return ResponseEntity.ok().contentType(MediaType.IMAGE_PNG).body(qrBytes);
    }

    @DeleteMapping("/items/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
    public ResponseEntity<Void> deleteMenuItem(@PathVariable UUID id) {
        menuService.deleteMenuItem(id);
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/categories/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
    public ResponseEntity<Void> deleteCategory(@PathVariable UUID id) {
        menuService.deleteCategory(id);
        return ResponseEntity.noContent().build();
    }
}
