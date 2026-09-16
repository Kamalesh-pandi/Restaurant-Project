package com.example.backend.table.repository;

import com.example.backend.table.entity.WaitlistEntry;
import com.example.backend.table.entity.WaitlistStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface WaitlistRepository extends JpaRepository<WaitlistEntry, UUID> {
    List<WaitlistEntry> findByStatusOrderByCreatedAtAsc(WaitlistStatus status);
    List<WaitlistEntry> findByOutletIdAndStatusOrderByCreatedAtAsc(UUID outletId, WaitlistStatus status);
}
