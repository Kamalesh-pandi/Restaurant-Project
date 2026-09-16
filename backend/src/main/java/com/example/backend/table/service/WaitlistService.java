package com.example.backend.table.service;

import com.example.backend.table.entity.RestaurantTable;
import com.example.backend.table.entity.TableStatus;
import com.example.backend.table.entity.WaitlistEntry;
import com.example.backend.table.entity.WaitlistStatus;
import com.example.backend.table.repository.WaitlistRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
public class WaitlistService {

    private final WaitlistRepository waitlistRepository;
    private final TableService tableService;

    public WaitlistService(WaitlistRepository waitlistRepository, TableService tableService) {
        this.waitlistRepository = waitlistRepository;
        this.tableService = tableService;
    }

    public List<WaitlistEntry> getAllWaitlist() {
        return waitlistRepository.findAll();
    }

    public List<WaitlistEntry> getWaitingList(UUID outletId) {
        if (outletId != null) {
            return waitlistRepository.findByOutletIdAndStatusOrderByCreatedAtAsc(outletId, WaitlistStatus.WAITING);
        }
        return waitlistRepository.findByStatusOrderByCreatedAtAsc(WaitlistStatus.WAITING);
    }

    @Transactional
    public WaitlistEntry addToWaitlist(WaitlistEntry entry) {
        if (entry.getOutletId() == null) {
            entry.setOutletId(UUID.randomUUID());
        }
        entry.setStatus(WaitlistStatus.WAITING);
        entry.setCreatedAt(LocalDateTime.now());
        return waitlistRepository.save(entry);
    }

    @Transactional
    public WaitlistEntry seatWaitlistEntry(UUID waitlistId, UUID tableId) {
        WaitlistEntry entry = waitlistRepository.findById(waitlistId)
                .orElseThrow(() -> new RuntimeException("Waitlist entry not found"));
        if (entry.getStatus() != WaitlistStatus.WAITING && entry.getStatus() != WaitlistStatus.NOTIFIED) {
            throw new RuntimeException("Waitlist guest is not in waiting or notified state");
        }

        // Lock table
        tableService.updateTableStatus(tableId, TableStatus.OCCUPIED);

        entry.setStatus(WaitlistStatus.SEATED);
        return waitlistRepository.save(entry);
    }

    @Transactional
    public WaitlistEntry cancelWaitlistEntry(UUID waitlistId) {
        WaitlistEntry entry = waitlistRepository.findById(waitlistId)
                .orElseThrow(() -> new RuntimeException("Waitlist entry not found"));
        entry.setStatus(WaitlistStatus.CANCELLED);
        return waitlistRepository.save(entry);
    }
}
