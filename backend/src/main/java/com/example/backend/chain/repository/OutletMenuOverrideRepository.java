package com.example.backend.chain.repository;

import com.example.backend.chain.entity.OutletMenuOverride;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface OutletMenuOverrideRepository extends JpaRepository<OutletMenuOverride, UUID> {
    Optional<OutletMenuOverride> findByOutletIdAndMenuItemId(UUID outletId, UUID menuItemId);
    List<OutletMenuOverride> findByOutletId(UUID outletId);
}
