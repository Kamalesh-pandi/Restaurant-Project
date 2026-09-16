import 'package:get/get.dart';
import '../../../data/providers/order_provider.dart';
import '../../../data/providers/payment_provider.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../../core/network/api_client.dart';
import '../controllers/payment_controller.dart';

class PaymentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OrderProvider>(() => OrderProvider(Get.find<ApiClient>()), fenix: true);
    Get.lazyPut<OrderRepository>(() => OrderRepository(Get.find<OrderProvider>()), fenix: true);
    Get.lazyPut<PaymentProvider>(() => PaymentProvider(Get.find<ApiClient>()), fenix: true);
    Get.lazyPut<PaymentRepository>(() => PaymentRepository(Get.find<PaymentProvider>()), fenix: true);
    Get.lazyPut<PaymentController>(() => PaymentController(), fenix: true);
  }
}
