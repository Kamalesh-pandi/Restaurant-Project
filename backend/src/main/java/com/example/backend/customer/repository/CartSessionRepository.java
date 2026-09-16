package com.example.backend.customer.repository;

import com.example.backend.customer.entity.CartSession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface CartSessionRepository extends JpaRepository<CartSession, UUID> {
    Optional<CartSession> findByPhone(String phone);
}
