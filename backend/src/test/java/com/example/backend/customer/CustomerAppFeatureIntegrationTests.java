package com.example.backend.customer;

import com.example.backend.customer.controller.CustomerAppController;
import com.example.backend.customer.dto.*;
import com.example.backend.customer.service.CartService;
import com.example.backend.customer.service.WishlistService;
import com.example.backend.menu.entity.MenuItem;
import com.example.backend.menu.repository.MenuItemRepository;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.ResponseEntity;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
public class CustomerAppFeatureIntegrationTests {

    @Autowired
    private CustomerAppController customerAppController;

    @Autowired
    private CartService cartService;

    @Autowired
    private WishlistService wishlistService;

    @Autowired
    private MenuItemRepository menuItemRepository;

    private String testPhone;

    @BeforeEach
    void setUp() {
        testPhone = "+91 9988776655";
        cartService.clearCart(testPhone);
    }

    @Test
    void testCartWorkflow() {
        // 1. Initially empty cart
        CartResponse cart = customerAppController.getCart(testPhone).getBody();
        assertNotNull(cart);
        assertTrue(cart.getCartItems().isEmpty());

        // 2. Add Item to Cart
        CartItemRequest itemReq = CartItemRequest.builder()
                .phone(testPhone)
                .cartItemId("item_burger_123")
                .quantity(2)
                .specialInstructions("Extra crispy fries")
                .item(Map.of(
                        "name", "Truffle Wagyu Burger",
                        "price", 450.00,
                        "description", "Gourmet beef burger",
                        "isVeg", false
                ))
                .build();

        CartResponse updatedCart = customerAppController.updateCartItem(itemReq).getBody();
        assertNotNull(updatedCart);
        assertEquals(1, updatedCart.getCartItems().size());

        // 3. Apply Coupon Code
        CouponRequest couponReq = CouponRequest.builder()
                .phone(testPhone)
                .couponCode("GOURMET50")
                .build();
        Map<String, Object> couponRes = customerAppController.applyCoupon(couponReq).getBody();
        assertNotNull(couponRes);
        assertEquals("GOURMET50", couponRes.get("appliedCoupon"));
        assertEquals(BigDecimal.valueOf(50.0), couponRes.get("discountAmount"));

        // 4. Clear Cart
        CartResponse clearedCart = customerAppController.clearCart(Map.of("phone", testPhone)).getBody();
        assertNotNull(clearedCart);
        assertTrue(clearedCart.getCartItems().isEmpty());
    }

    @Test
    void testWishlistWorkflow() {
        List<MenuItem> menu = customerAppController.getActiveMenu().getBody();
        assertNotNull(menu);
        assertFalse(menu.isEmpty());

        MenuItem item = menu.get(0);
        UUID itemId = item.getItemId();

        // 1. Toggle Wishlist Add
        WishlistToggleRequest toggleReq = WishlistToggleRequest.builder()
                .phone(testPhone)
                .menuItemId(itemId)
                .build();
        Map<String, Object> toggleRes = customerAppController.toggleWishlist(toggleReq).getBody();
        assertNotNull(toggleRes);
        assertEquals(true, toggleRes.get("isWishlisted"));

        // 2. Fetch Wishlist
        List<MenuItem> wishlist = customerAppController.getWishlist(testPhone).getBody();
        assertNotNull(wishlist);
        assertEquals(1, wishlist.size());
        assertEquals(itemId, wishlist.get(0).getItemId());

        // 3. Toggle Wishlist Remove
        Map<String, Object> toggleRemoveRes = customerAppController.toggleWishlist(toggleReq).getBody();
        assertNotNull(toggleRemoveRes);
        assertEquals(false, toggleRemoveRes.get("isWishlisted"));
    }

    @Test
    void testProfileUpdateAndModifiers() {
        // 1. Profile Update
        UpdateProfileRequest profileReq = UpdateProfileRequest.builder()
                .name("Alex Gourmet")
                .phone(testPhone)
                .email("alex@gourmet.com")
                .build();
        ResponseEntity<CustomerResponse> profileRes = customerAppController.updateCustomerProfile(profileReq);
        assertNotNull(profileRes.getBody());
        assertEquals("Alex Gourmet", profileRes.getBody().getName());

        // 2. Modifiers query
        List<Map<String, Object>> modifiers = customerAppController.getItemModifiers(UUID.randomUUID()).getBody();
        assertNotNull(modifiers);
        assertEquals(2, modifiers.size());
    }
}
