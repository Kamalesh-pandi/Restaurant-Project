package com.example.backend.menu.controller;

import com.example.backend.menu.entity.KitchenStation;
import com.example.backend.menu.repository.KitchenStationRepository;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/kitchen-stations")
public class KitchenStationController {

    private final KitchenStationRepository kitchenStationRepository;

    public KitchenStationController(KitchenStationRepository kitchenStationRepository) {
        this.kitchenStationRepository = kitchenStationRepository;
    }

    @GetMapping
    public ResponseEntity<List<KitchenStation>> getAllStations() {
        return ResponseEntity.ok(kitchenStationRepository.findAll());
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER', 'KITCHEN')")
    public ResponseEntity<KitchenStation> createStation(@RequestBody KitchenStation station) {
        if (station.getName() == null || station.getName().trim().isEmpty()) {
            throw new RuntimeException("Station name cannot be empty");
        }
        station.setName(station.getName().toUpperCase().trim());
        return ResponseEntity.status(HttpStatus.CREATED).body(kitchenStationRepository.save(station));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER', 'KITCHEN')")
    public ResponseEntity<Void> deleteStation(@PathVariable UUID id) {
        kitchenStationRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
