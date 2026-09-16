package com.example.backend.chain.repository;

import com.example.backend.chain.entity.CorporateNotification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface CorporateNotificationRepository extends JpaRepository<CorporateNotification, UUID> {
    List<CorporateNotification> findByBrandIdOrderBySentAtDesc(UUID brandId);
}
