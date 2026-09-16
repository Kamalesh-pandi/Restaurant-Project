import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/snackbars.dart';
import '../../../data/models/cart_item_model.dart';
import '../../../data/models/menu_item_model.dart';
import '../../../data/models/modifier_model.dart';
import '../../../data/models/order_model.dart';
import '../../../data/providers/cart_provider.dart';
import '../../../data/repositories/cart_repository.dart';
import '../../../data/services/storage_service.dart';

class CartController extends GetxController {
  final RxList<CartItemModel> cartItems = <CartItemModel>[].obs;
  final Rx<OrderType> selectedOrderType = OrderType.delivery.obs;
  final RxString dineInTable = ''.obs;
  final RxString deliveryAddress = ''.obs;
  final RxnString selectedAddressId = RxnString();
  final RxString promoCoupon = ''.obs;
  final RxDouble couponDiscount = 0.0.obs;
  final TextEditingController couponTextController = TextEditingController();

  CartRepository? _cartRepository;

  @override
  void onInit() {
    super.onInit();
    _initRepository();
    _fetchBackendCart();
  }

  void _initRepository() {
    try {
      if (Get.isRegistered<ApiClient>()) {
        final apiClient = Get.find<ApiClient>();
        final provider = CartProvider(apiClient);
        _cartRepository = CartRepository(provider);
      }
    } catch (_) {}
  }

  Future<void> _fetchBackendCart() async {
    try {
      final phone = Get.isRegistered<StorageService>()
          ? Get.find<StorageService>().user?.phone
          : null;
      if (phone != null && phone.isNotEmpty && _cartRepository != null) {
        final backendCart = await _cartRepository!.fetchCart(phone);
        if (backendCart.isNotEmpty) {
          cartItems.assignAll(backendCart);
        }
      }
    } catch (_) {}
  }

  void addToCart(
    MenuItemModel item, {
    int quantity = 1,
    List<ModifierOption> selectedModifiers = const [],
    String? specialInstructions,
  }) {
    final String cartItemId =
        '${item.id}_${selectedModifiers.map((m) => m.id).join('_')}';

    int existingIndex =
        cartItems.indexWhere((element) => element.cartItemId == cartItemId);

    late CartItemModel cartItem;

    if (existingIndex != -1) {
      cartItems[existingIndex].quantity += quantity;
      cartItem = cartItems[existingIndex];
      cartItems.refresh();
    } else {
      cartItem = CartItemModel(
        cartItemId: cartItemId,
        item: item,
        quantity: quantity,
        selectedModifiers: selectedModifiers,
        specialInstructions: specialInstructions,
      );
      cartItems.add(cartItem);
    }

    _syncItemToBackend(cartItem);

    AppSnackbars.showSuccess(
      title: 'Added to Cart',
      message: '${item.name} ($quantity) added to your order.',
    );
  }

  void incrementQuantity(int index) {
    if (index >= 0 && index < cartItems.length) {
      cartItems[index].quantity++;
      cartItems.refresh();
      _syncItemToBackend(cartItems[index]);
    }
  }

  void decrementQuantity(int index) {
    if (index >= 0 && index < cartItems.length) {
      if (cartItems[index].quantity > 1) {
        cartItems[index].quantity--;
        cartItems.refresh();
        _syncItemToBackend(cartItems[index]);
      } else {
        removeItem(index);
      }
    }
  }

  void removeItem(int index) {
    if (index >= 0 && index < cartItems.length) {
      final removed = cartItems[index];
      cartItems.removeAt(index);
      _removeBackendItem(removed.cartItemId);
      AppSnackbars.showInfo(
          title: 'Item Removed', message: '${removed.item.name} removed from cart.');
    }
  }

  void clearCart() {
    cartItems.clear();
    promoCoupon.value = '';
    couponDiscount.value = 0.0;
    _clearBackendCart();
  }

  void applyCoupon(String code) async {
    final trimmedCode = code.trim().toUpperCase();
    final phone = Get.isRegistered<StorageService>()
        ? Get.find<StorageService>().user?.phone
        : null;

    if (phone != null && phone.isNotEmpty && _cartRepository != null) {
      final discount = await _cartRepository!.applyCoupon(phone, trimmedCode);
      if (discount > 0) {
        promoCoupon.value = trimmedCode;
        couponDiscount.value = discount;
        AppSnackbars.showSuccess(
            title: 'Coupon Applied!',
            message: '₹${discount.toInt()} discount applied via backend!');
        return;
      }
    }

    // Local fallback coupon rules
    if (trimmedCode == 'GOURMET50') {
      promoCoupon.value = 'GOURMET50';
      couponDiscount.value = 50.0;
      AppSnackbars.showSuccess(
          title: 'Coupon Applied!', message: '₹50 discount applied to your bill.');
    } else if (trimmedCode == 'FIRST100') {
      promoCoupon.value = 'FIRST100';
      couponDiscount.value = 100.0;
      AppSnackbars.showSuccess(
          title: 'Coupon Applied!', message: '₹100 discount applied to your bill.');
    } else {
      AppSnackbars.showError(
          title: 'Invalid Coupon',
          message: 'Use GOURMET50 or FIRST100 for exclusive discount.');
    }
  }

  void _syncItemToBackend(CartItemModel item) {
    try {
      final phone = Get.isRegistered<StorageService>()
          ? Get.find<StorageService>().user?.phone
          : null;
      if (phone != null && phone.isNotEmpty && _cartRepository != null) {
        _cartRepository!.syncCartItem(phone, item);
      }
    } catch (_) {}
  }

  void _removeBackendItem(String cartItemId) {
    try {
      final phone = Get.isRegistered<StorageService>()
          ? Get.find<StorageService>().user?.phone
          : null;
      if (phone != null && phone.isNotEmpty && _cartRepository != null) {
        _cartRepository!.removeCartItem(phone, cartItemId);
      }
    } catch (_) {}
  }

  void _clearBackendCart() {
    try {
      final phone = Get.isRegistered<StorageService>()
          ? Get.find<StorageService>().user?.phone
          : null;
      if (phone != null && phone.isNotEmpty && _cartRepository != null) {
        _cartRepository!.clearCart(phone);
      }
    } catch (_) {}
  }

  // Calculations
  double get subtotal =>
      cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get gstAmount => subtotal * 0.05; // GST 5%
  double get deliveryFee => selectedOrderType.value == OrderType.delivery
      ? (subtotal > 500 ? 0.0 : 40.0)
      : 0.0;
  double get grandTotal => (subtotal + gstAmount + deliveryFee - couponDiscount.value)
      .clamp(0.0, double.infinity);
  int get itemCount => cartItems.fold(0, (sum, item) => sum + item.quantity);
}
