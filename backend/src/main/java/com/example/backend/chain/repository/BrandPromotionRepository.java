package com.example.backend.chain.repository;

import com.example.backend.chain.entity.BrandPromotion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface BrandPromotionRepository extends JpaRepository<BrandPromotion, UUID> {
    List<BrandPromotion> findByBrandIdAndIsActiveTrue(UUID brandId);
}
