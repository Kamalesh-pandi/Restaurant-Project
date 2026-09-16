package com.example.backend.customer.service;

import com.example.backend.customer.entity.Wishlist;
import com.example.backend.customer.repository.WishlistRepository;
import com.example.backend.menu.entity.MenuItem;
import com.example.backend.menu.repository.MenuItemRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
public class WishlistService {

    private final WishlistRepository wishlistRepository;
    private final MenuItemRepository menuItemRepository;

    public WishlistService(WishlistRepository wishlistRepository, MenuItemRepository menuItemRepository) {
        this.wishlistRepository = wishlistRepository;
        this.menuItemRepository = menuItemRepository;
    }

    public List<MenuItem> getWishlist(String phone) {
        List<Wishlist> wishlists = wishlistRepository.findByPhone(phone);
        List<UUID> itemIds = wishlists.stream().map(Wishlist::getMenuItemId).collect(Collectors.toList());
        if (itemIds.isEmpty()) {
            return Collections.emptyList();
        }
        return menuItemRepository.findAllById(itemIds);
    }

    @Transactional
    public Map<String, Object> toggleWishlist(String phone, UUID menuItemId) {
        Optional<Wishlist> existing = wishlistRepository.findByPhoneAndMenuItemId(phone, menuItemId);
        boolean isWishlisted;
        if (existing.isPresent()) {
            wishlistRepository.deleteByPhoneAndMenuItemId(phone, menuItemId);
            isWishlisted = false;
        } else {
            Wishlist wishlist = Wishlist.builder()
                    .phone(phone)
                    .menuItemId(menuItemId)
                    .build();
            wishlistRepository.save(wishlist);
            isWishlisted = true;
        }

        Map<String, Object> response = new HashMap<>();
        response.put("phone", phone);
        response.put("menuItemId", menuItemId);
        response.put("isWishlisted", isWishlisted);
        return response;
    }
}
