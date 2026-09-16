package com.example.backend.customer.service;

import com.example.backend.customer.dto.CartItemRequest;
import com.example.backend.customer.dto.CartResponse;
import com.example.backend.customer.entity.CartItem;
import com.example.backend.customer.entity.CartSession;
import com.example.backend.customer.repository.CartItemRepository;
import com.example.backend.customer.repository.CartSessionRepository;
import com.example.backend.menu.entity.MenuItem;
import com.example.backend.menu.repository.MenuItemRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.*;

@Service
public class CartService {

    private final CartItemRepository cartItemRepository;
    private final CartSessionRepository cartSessionRepository;
    private final MenuItemRepository menuItemRepository;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public CartService(CartItemRepository cartItemRepository,
                       CartSessionRepository cartSessionRepository,
                       MenuItemRepository menuItemRepository) {
        this.cartItemRepository = cartItemRepository;
        this.cartSessionRepository = cartSessionRepository;
        this.menuItemRepository = menuItemRepository;
    }

    public CartResponse getCart(String phone) {
        List<CartItem> items = cartItemRepository.findByPhone(phone);
        CartSession session = cartSessionRepository.findByPhone(phone).orElse(null);

        List<Map<String, Object>> cartItemsList = new ArrayList<>();
        for (CartItem item : items) {
            Map<String, Object> map = new HashMap<>();
            map.put("cartItemId", item.getCartItemId());
            map.put("quantity", item.getQuantity());

            List<Object> modifiersList = new ArrayList<>();
            if (item.getSelectedModifiers() != null && !item.getSelectedModifiers().isBlank()) {
                try {
                    modifiersList = objectMapper.readValue(item.getSelectedModifiers(), List.class);
                } catch (Exception e) {
                    // Fallback to simple string item
                    modifiersList.add(Map.of("id", "mod_1", "name", item.getSelectedModifiers(), "extraPrice", 0));
                }
            }
            map.put("selectedModifiers", modifiersList);
            map.put("specialInstructions", item.getSpecialInstructions());

            Map<String, Object> itemMap = new HashMap<>();
            itemMap.put("itemId", item.getMenuItemId() != null ? item.getMenuItemId().toString() : item.getCartItemId());
            itemMap.put("id", item.getMenuItemId() != null ? item.getMenuItemId().toString() : item.getCartItemId());
            itemMap.put("name", item.getItemName() != null ? item.getItemName() : "Item");
            itemMap.put("description", item.getItemDescription() != null ? item.getItemDescription() : "");
            itemMap.put("price", item.getItemPrice() != null ? item.getItemPrice() : BigDecimal.ZERO);
            itemMap.put("imageUrl", item.getItemImageUrl() != null ? item.getItemImageUrl() : "https://images.unsplash.com/photo-1546069901-ba9599a7e63c");
            itemMap.put("isVeg", item.getIsVeg() != null ? item.getIsVeg() : true);
            map.put("item", itemMap);

            cartItemsList.add(map);
        }

        return CartResponse.builder()
                .phone(phone)
                .cartItems(cartItemsList)
                .appliedCoupon(session != null ? session.getAppliedCoupon() : null)
                .discountAmount(session != null && session.getDiscountAmount() != null ? session.getDiscountAmount() : BigDecimal.ZERO)
                .build();
    }

    @Transactional
    public CartResponse updateCartItem(CartItemRequest request) {
        String phone = request.getPhone();
        if (phone == null || phone.isBlank()) {
            throw new RuntimeException("Phone number is required");
        }

        String cartItemId = request.getCartItemId();
        if (cartItemId == null || cartItemId.isBlank()) {
            cartItemId = "item_" + System.currentTimeMillis();
        }

        Optional<CartItem> existingOpt = cartItemRepository.findByPhoneAndCartItemId(phone, cartItemId);
        CartItem cartItem = existingOpt.orElseGet(() -> CartItem.builder()
                .phone(phone)
                .cartItemId(request.getCartItemId())
                .build());

        if (request.getQuantity() != null) {
            cartItem.setQuantity(request.getQuantity());
        }

        if (request.getSpecialInstructions() != null) {
            cartItem.setSpecialInstructions(request.getSpecialInstructions());
        }

        if (request.getSelectedModifiers() != null) {
            try {
                if (request.getSelectedModifiers() instanceof String) {
                    cartItem.setSelectedModifiers((String) request.getSelectedModifiers());
                } else {
                    cartItem.setSelectedModifiers(objectMapper.writeValueAsString(request.getSelectedModifiers()));
                }
            } catch (Exception e) {
                cartItem.setSelectedModifiers(request.getSelectedModifiers().toString());
            }
        }

        if (request.getMenuItemId() != null) {
            cartItem.setMenuItemId(request.getMenuItemId());
            menuItemRepository.findById(request.getMenuItemId()).ifPresent(mi -> {
                cartItem.setItemName(mi.getName());
                cartItem.setItemDescription(mi.getDescription());
                cartItem.setItemPrice(mi.getPrice());
                cartItem.setItemImageUrl(mi.getImageUrl());
                cartItem.setIsVeg(mi.isVeg());
            });
        } else if (request.getItem() != null) {
            Map<String, Object> itemMap = request.getItem();
            if (itemMap.get("id") != null || itemMap.get("itemId") != null) {
                String idStr = itemMap.get("id") != null ? itemMap.get("id").toString() : itemMap.get("itemId").toString();
                try {
                    cartItem.setMenuItemId(UUID.fromString(idStr));
                } catch (Exception ignored) {}
            }
            if (itemMap.get("name") != null) cartItem.setItemName(itemMap.get("name").toString());
            if (itemMap.get("description") != null) cartItem.setItemDescription(itemMap.get("description").toString());
            if (itemMap.get("price") != null) {
                try {
                    cartItem.setItemPrice(new BigDecimal(itemMap.get("price").toString()));
                } catch (Exception ignored) {}
            }
            if (itemMap.get("imageUrl") != null) cartItem.setItemImageUrl(itemMap.get("imageUrl").toString());
            if (itemMap.get("isVeg") != null) cartItem.setIsVeg(Boolean.parseBoolean(itemMap.get("isVeg").toString()));
        }

        if (cartItem.getCartItemId() == null) {
            cartItem.setCartItemId(cartItemId);
        }

        cartItemRepository.save(cartItem);
        return getCart(phone);
    }

    @Transactional
    public CartResponse removeCartItem(String phone, String cartItemId) {
        cartItemRepository.deleteByPhoneAndCartItemId(phone, cartItemId);
        return getCart(phone);
    }

    @Transactional
    public CartResponse clearCart(String phone) {
        cartItemRepository.deleteByPhone(phone);
        cartSessionRepository.findByPhone(phone).ifPresent(cartSessionRepository::delete);
        return getCart(phone);
    }

    @Transactional
    public Map<String, Object> applyCoupon(String phone, String couponCode) {
        if (couponCode == null) couponCode = "";
        String code = couponCode.trim().toUpperCase();

        BigDecimal discount = BigDecimal.ZERO;
        if ("GOURMET50".equals(code)) {
            discount = BigDecimal.valueOf(50.0);
        } else if ("FIRST100".equals(code)) {
            discount = BigDecimal.valueOf(100.0);
        } else if (!code.isBlank()) {
            discount = BigDecimal.valueOf(30.0); // Generic promo code reward
        }

        CartSession session = cartSessionRepository.findByPhone(phone).orElseGet(() -> CartSession.builder().phone(phone).build());
        session.setAppliedCoupon(code);
        session.setDiscountAmount(discount);
        cartSessionRepository.save(session);

        Map<String, Object> response = new HashMap<>();
        response.put("phone", phone);
        response.put("appliedCoupon", code);
        response.put("discountAmount", discount);
        return response;
    }
}
