import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

class WishlistProvider {
  final ApiClient _apiClient;

  WishlistProvider(this._apiClient);

  Future<List<dynamic>> getWishlist(String phone) async {
    final response = await _apiClient.get(ApiConstants.customerWishlist(phone));
    if (response is List) {
      return response;
    } else if (response is Map && response['data'] is List) {
      return response['data'] as List;
    }
    return [];
  }

  Future<Map<String, dynamic>> toggleWishlist(String phone, String itemId) async {
    final response = await _apiClient.post(
      ApiConstants.toggleWishlist,
      data: {
        'phone': phone,
        'menuItemId': itemId,
        'itemId': itemId,
      },
    );
    return response as Map<String, dynamic>;
  }
}
