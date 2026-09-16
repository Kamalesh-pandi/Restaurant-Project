package com.example.backend.inventory.repository;

import com.example.backend.inventory.entity.DailyStockSheet;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface DailyStockSheetRepository extends JpaRepository<DailyStockSheet, UUID> {
    Optional<DailyStockSheet> findByIngredientIdAndStockDate(UUID ingredientId, LocalDate date);
    List<DailyStockSheet> findByStockDate(LocalDate date);
}
