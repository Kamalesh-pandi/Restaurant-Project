package com.example.backend.inventory.repository;

import com.example.backend.inventory.entity.PerishableBatch;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface PerishableBatchRepository extends JpaRepository<PerishableBatch, UUID> {
    List<PerishableBatch> findByIngredientIdOrderByPurchaseDateAsc(UUID ingredientId);
}
