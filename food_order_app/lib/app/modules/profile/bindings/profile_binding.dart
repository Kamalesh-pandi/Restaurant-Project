import 'package:get/get.dart';
import '../../../data/providers/customer_provider.dart';
import '../../../data/providers/order_provider.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../core/network/api_client.dart';
import '../controllers/profile_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CustomerProvider>(() => CustomerProvider(Get.find<ApiClient>()), fenix: true);
    Get.lazyPut<CustomerRepository>(() => CustomerRepository(Get.find<CustomerProvider>()), fenix: true);
    Get.lazyPut<OrderProvider>(() => OrderProvider(Get.find<ApiClient>()), fenix: true);
    Get.lazyPut<OrderRepository>(() => OrderRepository(Get.find<OrderProvider>()), fenix: true);
    Get.lazyPut<ProfileController>(() => ProfileController(), fenix: true);
  }
}
