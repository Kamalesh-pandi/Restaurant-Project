import 'package:get/get.dart';
import '../../../data/providers/order_provider.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../core/network/api_client.dart';
import '../controllers/tracking_controller.dart';

class TrackingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OrderProvider>(() => OrderProvider(Get.find<ApiClient>()), fenix: true);
    Get.lazyPut<OrderRepository>(() => OrderRepository(Get.find<OrderProvider>()), fenix: true);
    Get.lazyPut<TrackingController>(() => TrackingController(), fenix: true);
  }
}
