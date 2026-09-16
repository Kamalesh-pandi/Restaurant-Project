import '../models/cart_item_model.dart';
import '../providers/cart_provider.dart';

class CartRepository {
  final CartProvider _cartProvider;

  CartRepository(this._cartProvider);

  Future<List<CartItemModel>> fetchCart(String phone) async {
    try {
      final res = await _cartProvider.getCart(phone);
      if (res['cartItems'] is List) {
        return (res['cartItems'] as List)
            .map((e) => CartItemModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> syncCartItem(String phone, CartItemModel cartItem) async {
    try {
      await _cartProvider.updateCartItem(phone, cartItem.toJson());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeCartItem(String phone, String cartItemId) async {
    try {
      await _cartProvider.removeCartItem(phone, cartItemId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> clearCart(String phone) async {
    try {
      await _cartProvider.clearCart(phone);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<double> applyCoupon(String phone, String couponCode) async {
    try {
      final res = await _cartProvider.applyCoupon(phone, couponCode);
      return (res['discountAmount'] as num?)?.toDouble() ?? 0.0;
    } catch (_) {
      return 0.0;
    }
  }
}
