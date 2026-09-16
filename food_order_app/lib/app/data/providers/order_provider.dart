import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

class OrderProvider {
  final ApiClient _apiClient;

  OrderProvider(this._apiClient);

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> payload) async {
    final response = await _apiClient.post(
      ApiConstants.createOrder,
      data: payload,
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getOrderTimeline(String orderId) async {
    final response = await _apiClient.get(ApiConstants.orderTimeline(orderId));
    return response as Map<String, dynamic>;
  }

  Future<List<dynamic>> getOrderHistory(String phone) async {
    final response = await _apiClient.get(ApiConstants.customerOrderHistory(phone));
    if (response is List) {
      return response;
    } else if (response is Map && response['data'] is List) {
      return response['data'] as List;
    }
    return [];
  }
}
