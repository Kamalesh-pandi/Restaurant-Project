package com.example.backend.customer.repository;

import com.example.backend.customer.entity.CustomerVisit;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface CustomerVisitRepository extends JpaRepository<CustomerVisit, UUID> {
    List<CustomerVisit> findByCustomerId(UUID customerId);
}
