import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayService {
  late Razorpay _razorpay;

  Function(PaymentSuccessResponse)? onSuccess;
  Function(PaymentFailureResponse)? onError;
  Function(ExternalWalletResponse)? onExternalWallet;

  void initialize({
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onError,
    Function(ExternalWalletResponse)? onExternalWallet,
  }) {
    _razorpay = Razorpay();
    this.onSuccess = onSuccess;
    this.onError = onError;
    this.onExternalWallet = onExternalWallet;

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (kDebugMode) print('Razorpay Payment Success: ${response.paymentId}');
    onSuccess?.call(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (kDebugMode) print('Razorpay Payment Error: ${response.code} - ${response.message}');
    onError?.call(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (kDebugMode) print('Razorpay External Wallet: ${response.walletName}');
    onExternalWallet?.call(response);
  }

  void openCheckout({
    required String keyId,
    required String razorpayOrderId,
    required double amountInRupees,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    String description = 'Food Order Payment',
  }) {
    final Map<String, dynamic> options = {
      'key': keyId.isNotEmpty ? keyId : 'rzp_test_5W9Z38Qk2X1Y',
      'amount': (amountInRupees * 100).toInt(),
      'name': 'Spice Haven',
      'description': description,
      'timeout': 300,
      'prefill': {
        'contact': customerPhone.isNotEmpty ? customerPhone : '9876543210',
        'email': customerEmail.isNotEmpty ? customerEmail : 'customer@spicehaven.com',
        'name': customerName.isNotEmpty ? customerName : 'Valued Customer',
      },
      'theme': {
        'color': '#C59B27',
      }
    };

    // Only attach order_id if it's a real Razorpay server order ID
    if (razorpayOrderId.isNotEmpty && !razorpayOrderId.startsWith('order_rzp_mock_')) {
      options['order_id'] = razorpayOrderId;
    }

    try {
      _razorpay.open(options);
    } catch (e) {
      if (kDebugMode) print('Error launching Razorpay: $e');
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}
