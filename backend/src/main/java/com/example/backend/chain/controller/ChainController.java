package com.example.backend.chain.controller;

import com.example.backend.chain.dto.*;
import com.example.backend.chain.entity.*;
import com.example.backend.chain.service.ChainService;
import com.example.backend.menu.entity.MenuItem;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/chain")
public class ChainController {

    private final ChainService chainService;

    public ChainController(ChainService chainService) {
        this.chainService = chainService;
    }

    @PostMapping("/brands")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Brand> createBrand(@RequestBody Brand brand) {
        return ResponseEntity.status(HttpStatus.CREATED).body(chainService.createBrand(brand));
    }

    @PostMapping("/outlets")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Outlet> createOutlet(@RequestBody Outlet outlet) {
        return ResponseEntity.status(HttpStatus.CREATED).body(chainService.createOutlet(outlet));
    }

    @GetMapping("/outlets")
    public ResponseEntity<List<Outlet>> getAllOutlets() {
        return ResponseEntity.ok(chainService.getAllOutlets());
    }

    @PostMapping("/menu/push")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<MenuItem>> pushMenuToOutlets(@RequestBody PushMenuRequest request) {
        return ResponseEntity.ok(chainService.pushMenuToOutlets(request));
    }

    @PostMapping("/menu/override")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<OutletMenuOverride> saveOutletOverride(@RequestBody OverrideMenuRequest request) {
        return ResponseEntity.ok(chainService.saveOutletOverride(request));
    }

    @PostMapping("/menu/broadcast-unavailability")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<String> broadcastItemUnavailability(@RequestParam String menuItemName, @RequestParam boolean isAvailable) {
        chainService.broadcastItemUnavailability(menuItemName, isAvailable);
        return ResponseEntity.ok("Item availability broadcast complete for " + menuItemName);
    }

    @GetMapping("/promotions")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER', 'CASHIER')")
    public ResponseEntity<List<BrandPromotion>> getAllPromotions() {
        return ResponseEntity.ok(chainService.getAllPromotions());
    }

    @PostMapping("/promotions")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
    public ResponseEntity<BrandPromotion> createBrandPromotion(@RequestBody BrandPromotion promotion) {
        return ResponseEntity.status(HttpStatus.CREATED).body(chainService.createBrandPromotion(promotion));
    }

    @PutMapping("/outlets/{id}/mystery-audit")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Outlet> toggleMysteryAudit(@PathVariable UUID id, @RequestParam boolean active) {
        return ResponseEntity.ok(chainService.toggleMysteryAudit(id, active));
    }

    @PostMapping("/notifications/broadcast")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<CorporateNotification> broadcastCorporateNotification(@RequestParam(required = false) UUID brandId,
                                                                                 @RequestParam String title,
                                                                                 @RequestParam String message) {
        return ResponseEntity.ok(chainService.broadcastCorporateNotification(brandId, title, message));
    }

    @GetMapping("/outlets/{id}/royalty")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<BigDecimal> calculateFranchiseRoyalty(@PathVariable UUID id) {
        return ResponseEntity.ok(chainService.calculateFranchiseRoyalty(id));
    }

    @GetMapping("/reports/consolidated")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ConsolidatedChainReportResponse> getConsolidatedChainReport() {
        return ResponseEntity.ok(chainService.getConsolidatedChainReport());
    }

    @GetMapping("/reports/comparison")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<OutletComparisonResponse>> getOutletComparisons() {
        return ResponseEntity.ok(chainService.getOutletComparisons());
    }
}
