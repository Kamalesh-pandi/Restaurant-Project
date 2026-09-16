package com.example.backend.customer.repository;

import com.example.backend.customer.entity.Wishlist;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface WishlistRepository extends JpaRepository<Wishlist, UUID> {
    List<Wishlist> findByPhone(String phone);
    Optional<Wishlist> findByPhoneAndMenuItemId(String phone, UUID menuItemId);
    void deleteByPhoneAndMenuItemId(String phone, UUID menuItemId);
}
