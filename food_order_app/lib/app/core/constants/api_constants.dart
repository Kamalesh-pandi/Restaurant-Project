import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  // Base URL resolution for Local Host vs Android Emulator
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080';
    } else if (Platform.isAndroid) {
      // http://localhost:8080 works over USB with adb reverse, fallback handles LAN/Emulator
      return 'http://localhost:8080';
    } else {
      return 'http://localhost:8080';
    }
  }

  static const int connectTimeout = 2500; // 2.5s for fast host fallback
  static const int receiveTimeout = 15000; // 15s

  // Auth & Account Endpoints
  static const String login = '/api/auth/login';
  static const String signup = '/api/v1/customer-app/signup';

  // Menu & Categories Endpoints
  static const String categories = '/api/v1/customer-app/categories';
  static const String menuItems = '/api/v1/customer-app/menu';
  static const String menuItemsByCategory = '/api/v1/customer-app/menu/category/';
  static const String specials = '/api/v1/customer-app/menu';
  static String itemModifiers(dynamic id) => '/api/v1/customer-app/menu/$id/modifiers';

  // Order & Tracking Endpoints
  static const String createOrder = '/api/v1/customer-app/orders';
  static String orderTimeline(dynamic id) => '/api/v1/customer-app/orders/$id/track';
  static String customerOrderHistory(String phone) => '/api/v1/customer-app/orders/history?phone=$phone';

  // Razorpay Payment & Billing
  static String createRazorpayOrder(dynamic orderId, double amount) =>
      '/api/v1/payments/razorpay/create-order?orderId=$orderId&amount=$amount';
  static String settleBill(dynamic billId) => '/api/v1/bills/$billId/settle';

  // Reservations & Tables
  static const String onlineReservation = '/api/v1/customer-app/reservations';
  static String outletTables(dynamic outletId) => '/api/v1/customer-app/tables/$outletId';
  static String customerReservationHistory(String phone) =>
      '/api/v1/customer-app/reservations/history?phone=$phone';
  static String cancelReservation(dynamic id) =>
      '/api/v1/customer-app/reservations/$id/cancel';

  // Customer Profile & Feedback
  static String customerProfile(dynamic id) => '/api/v1/customer-app/profile?customerId=$id';
  static String customerProfileByPhone(String phone) => '/api/v1/customer-app/profile?phone=$phone';
  static const String updateProfile = '/api/v1/customer-app/profile/update';
  static const String customerFeedback = '/api/v1/customer-app/feedback';

  // Customer Addresses Endpoints
  static String customerAddresses(String phone, {String? customerId}) =>
      customerId != null && customerId.isNotEmpty
          ? '/api/v1/customer-app/addresses?phone=$phone&customerId=$customerId'
          : '/api/v1/customer-app/addresses?phone=$phone';
  static String customerAddressDetail(String addressId) =>
      '/api/v1/customer-app/addresses/$addressId';
  static String setDefaultAddress(String addressId, String phone, {String? customerId}) =>
      customerId != null && customerId.isNotEmpty
          ? '/api/v1/customer-app/addresses/$addressId/default?phone=$phone&customerId=$customerId'
          : '/api/v1/customer-app/addresses/$addressId/default?phone=$phone';

  // Wishlist Endpoints
  static String customerWishlist(String phone) => '/api/v1/customer-app/wishlist?phone=$phone';
  static const String toggleWishlist = '/api/v1/customer-app/wishlist/toggle';

  // Cart Endpoints
  static String customerCart(String phone) => '/api/v1/customer-app/cart?phone=$phone';
  static const String updateCartItem = '/api/v1/customer-app/cart/item';
  static String removeCartItem(String cartItemId) => '/api/v1/customer-app/cart/item/$cartItemId';
  static const String clearCart = '/api/v1/customer-app/cart/clear';
  static const String applyCoupon = '/api/v1/customer-app/cart/apply-coupon';
}
