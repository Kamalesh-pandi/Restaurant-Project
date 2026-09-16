package com.example.backend.customer.repository;

import com.example.backend.customer.entity.CustomerAddress;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface CustomerAddressRepository extends JpaRepository<CustomerAddress, UUID> {
    List<CustomerAddress> findByCustomerIdOrderByIsDefaultDescCreatedAtDesc(UUID customerId);
    Optional<CustomerAddress> findByCustomerIdAndIsDefaultTrue(UUID customerId);
    void deleteByAddressIdAndCustomerId(UUID addressId, UUID customerId);
}
