import '../providers/payment_provider.dart';

class PaymentRepository {
  final PaymentProvider _paymentProvider;

  PaymentRepository(this._paymentProvider);

  Future<Map<String, String>> createRazorpayOrder(String orderId, double amount) async {
    final res = await _paymentProvider.createRazorpayOrder(orderId, amount);
    return {
      'keyId': res['keyId']?.toString() ?? 'rzp_test_5W9Z38Qk2X1Y',
      'razorpayOrderId': res['razorpayOrderId']?.toString() ?? res['id']?.toString() ?? 'order_rzp_${DateTime.now().millisecondsSinceEpoch}',
    };
  }

  Future<bool> settleBill(String orderId, String razorpayPaymentId) async {
    await _paymentProvider.settleBill(orderId, razorpayPaymentId);
    return true;
  }
}
