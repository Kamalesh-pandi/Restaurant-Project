package com.example.backend.table.repository;

import com.example.backend.table.entity.RestaurantTable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface RestaurantTableRepository extends JpaRepository<RestaurantTable, UUID> {
    List<RestaurantTable> findByOutletId(UUID outletId);
    List<RestaurantTable> findByParentTableId(UUID parentTableId);
    List<RestaurantTable> findByOutletIdAndSectionIgnoreCase(UUID outletId, String section);
    List<RestaurantTable> findBySectionIgnoreCase(String section);
}
