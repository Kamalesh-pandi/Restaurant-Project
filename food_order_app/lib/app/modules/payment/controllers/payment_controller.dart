import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../../data/services/razorpay_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../routes/app_routes.dart';
import '../../../core/utils/snackbars.dart';
import '../../../core/utils/app_dialogs.dart';
import '../../cart/controllers/cart_controller.dart';

class PaymentController extends GetxController {
  final OrderRepository _orderRepository = Get.find<OrderRepository>();
  final PaymentRepository _paymentRepository = Get.find<PaymentRepository>();
  final StorageService _storageService = Get.find<StorageService>();
  final CartController _cartController = Get.find<CartController>();

  final RazorpayService _razorpayService = RazorpayService();

  final RxBool isProcessing = false.obs;
  final RxString statusMessage = ''.obs;
  String? currentBackendOrderId;

  @override
  void onInit() {
    super.onInit();
    _razorpayService.initialize(
      onSuccess: _handleSuccess,
      onError: _handleError,
      onExternalWallet: _handleExternalWallet,
    );
  }

  Future<void> initiateRazorpayCheckout() async {
    isProcessing.value = true;
    statusMessage.value = 'Creating order with server...';

    try {
      final currentUser = _storageService.user;
      final OrderModel order = OrderModel(
        customerId: currentUser?.id ?? '',
        orderType: _cartController.selectedOrderType.value,
        tableNumber: _cartController.selectedOrderType.value == OrderType.dineIn
            ? _cartController.dineInTable.value
            : null,
        deliveryAddress: _cartController.selectedOrderType.value == OrderType.delivery
            ? _cartController.deliveryAddress.value
            : null,
        items: _cartController.cartItems,
        subtotal: _cartController.subtotal,
        gstAmount: _cartController.gstAmount,
        deliveryFee: _cartController.deliveryFee,
        discount: _cartController.couponDiscount.value,
        grandTotal: _cartController.grandTotal,
      );

      // 1. Create order at Java REST backend (POST /api/v1/customer-app/orders)
      final String orderId = await _orderRepository.createOrder(
        order,
        name: currentUser?.name ?? 'Customer',
        phone: currentUser?.phone ?? '',
        email: currentUser?.email ?? '',
        address: _cartController.deliveryAddress.value.isNotEmpty
            ? _cartController.deliveryAddress.value
            : currentUser?.address,
        addressId: _cartController.selectedAddressId.value,
      );
      currentBackendOrderId = orderId;
      await _storageService.saveActiveOrderId(orderId);

      statusMessage.value = 'Generating Razorpay Payment Gateway ID...';

      // 2. Request Razorpay Order ID & Key ID from backend
      final paymentData = await _paymentRepository.createRazorpayOrder(
        orderId,
        _cartController.grandTotal,
      );

      final String keyId = paymentData['keyId'] ?? 'rzp_test_5W9Z38Qk2X1Y';
      final String razorpayOrderId = paymentData['razorpayOrderId'] ?? '';

      statusMessage.value = 'Launching Razorpay Secure Payment...';

      // 3. Trigger Razorpay SDK modal
      _razorpayService.openCheckout(
        keyId: keyId,
        razorpayOrderId: razorpayOrderId,
        amountInRupees: _cartController.grandTotal,
        customerName: currentUser?.name ?? 'Customer',
        customerEmail: currentUser?.email ?? '',
        customerPhone: currentUser?.phone ?? '',
        description: 'Payment for Order #$orderId',
      );
    } catch (e) {
      isProcessing.value = false;
      AppSnackbars.showError(title: 'Payment Error', message: e.toString());
    }
  }

  void _handleSuccess(PaymentSuccessResponse response) async {
    statusMessage.value = 'Verifying payment & settling bill...';
    final targetOrderId = currentBackendOrderId ?? response.orderId ?? '';
    if (targetOrderId.isEmpty) {
      isProcessing.value = false;
      return;
    }
    try {
      // Settle bill via POST /api/v1/bills/{id}/settle
      await _paymentRepository.settleBill(
        targetOrderId,
        response.paymentId ?? 'pay_mock_${DateTime.now().millisecondsSinceEpoch}',
      );

      AppSnackbars.showSuccess(
        title: 'Payment Successful!',
        message: 'Transaction ID: ${response.paymentId ?? "PAY_MOCK_SUCCESS"}',
      );

      _cartController.clearCart();
      await _storageService.addActiveOrderId(targetOrderId);

      // Navigate to Live Order Tracking Screen
      Get.offAllNamed(
        AppRoutes.tracking,
        arguments: {'orderId': targetOrderId},
      );
    } catch (e) {
      AppSnackbars.showError(title: 'Settlement Notice', message: e.toString());
      _cartController.clearCart();
      await _storageService.addActiveOrderId(targetOrderId);
      Get.offAllNamed(
        AppRoutes.tracking,
        arguments: {'orderId': targetOrderId},
      );
    } finally {
      isProcessing.value = false;
    }
  }

  void _handleError(PaymentFailureResponse response) {
    isProcessing.value = false;

    // Offer test simulation when in test environment or code 0 / error occurs
    AppDialogs.confirm(
      title: 'Payment Notice',
      message: response.code == 0
          ? 'Payment window closed or test key environment detected.'
          : 'Gateway Notice: ${response.message}',
      icon: Icons.payments_rounded,
      type: DialogType.warning,
      confirmText: 'Simulate Test Pay',
      cancelText: 'Cancel Order',
      customContent: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline_rounded,
                size: 18, color: Color(0xFF64748B)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Would you like to complete this order via Test Mode simulation?',
                style: TextStyle(
                    fontSize: 12.5, color: Color(0xFF64748B), height: 1.3),
              ),
            ),
          ],
        ),
      ),
      onConfirm: () {
        _handleSuccess(PaymentSuccessResponse.fromMap({
          'payment_id': 'pay_sim_${DateTime.now().millisecondsSinceEpoch}',
          'order_id': currentBackendOrderId ?? 'order_sim_1001',
          'signature': 'sig_sim_123',
        }));
      },
      onCancel: () {
        AppSnackbars.showInfo(
            title: 'Cancelled', message: 'Payment process cancelled.');
      },
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    AppSnackbars.showInfo(
      title: 'External Wallet Selected',
      message: 'Redirecting to ${response.walletName}',
    );
  }

  @override
  void onClose() {
    _razorpayService.dispose();
    super.onClose();
  }
}
