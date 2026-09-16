package com.example.backend.customer.repository;

import com.example.backend.customer.entity.CartItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface CartItemRepository extends JpaRepository<CartItem, UUID> {
    List<CartItem> findByPhone(String phone);
    Optional<CartItem> findByPhoneAndCartItemId(String phone, String cartItemId);
    void deleteByPhoneAndCartItemId(String phone, String cartItemId);
    void deleteByPhone(String phone);
}
