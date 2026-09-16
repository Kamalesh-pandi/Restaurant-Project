package com.example.backend.bill.repository;

import com.example.backend.bill.entity.Bill;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface BillRepository extends JpaRepository<Bill, UUID> {
    Optional<Bill> findByOrderId(UUID orderId);
    Optional<Bill> findByBillNumber(String billNumber);
    List<Bill> findAllByOrderId(UUID orderId);
}
