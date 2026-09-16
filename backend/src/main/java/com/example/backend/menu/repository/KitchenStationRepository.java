package com.example.backend.menu.repository;

import com.example.backend.menu.entity.KitchenStation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface KitchenStationRepository extends JpaRepository<KitchenStation, UUID> {
    Optional<KitchenStation> findByNameIgnoreCase(String name);
}
