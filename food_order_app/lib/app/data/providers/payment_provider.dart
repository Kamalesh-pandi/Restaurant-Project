import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

class PaymentProvider {
  final ApiClient _apiClient;

  PaymentProvider(this._apiClient);

  Future<Map<String, dynamic>> createRazorpayOrder(String orderId, double amount) async {
    final response = await _apiClient.post(
      ApiConstants.createRazorpayOrder(orderId, amount),
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> settleBill(String billId, String paymentId) async {
    final response = await _apiClient.post(
      ApiConstants.settleBill(billId),
      data: {'razorpayPaymentId': paymentId, 'status': 'PAID'},
    );
    return response as Map<String, dynamic>;
  }
}
