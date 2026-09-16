import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

class CartProvider {
  final ApiClient _apiClient;

  CartProvider(this._apiClient);

  Future<Map<String, dynamic>> getCart(String phone) async {
    final response = await _apiClient.get(ApiConstants.customerCart(phone));
    return response is Map<String, dynamic> ? response : {'cartItems': []};
  }

  Future<Map<String, dynamic>> updateCartItem(String phone, Map<String, dynamic> cartItemData) async {
    final response = await _apiClient.post(
      ApiConstants.updateCartItem,
      data: {
        'phone': phone,
        ...cartItemData,
      },
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> removeCartItem(String phone, String cartItemId) async {
    final response = await _apiClient.delete(
      ApiConstants.removeCartItem(cartItemId),
      data: {'phone': phone},
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> clearCart(String phone) async {
    final response = await _apiClient.post(
      ApiConstants.clearCart,
      data: {'phone': phone},
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> applyCoupon(String phone, String couponCode) async {
    final response = await _apiClient.post(
      ApiConstants.applyCoupon,
      data: {
        'phone': phone,
        'couponCode': couponCode,
      },
    );
    return response as Map<String, dynamic>;
  }
}
