import 'package:get/get.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/customer_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../core/network/api_client.dart';
import '../controllers/auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthProvider>(() => AuthProvider(Get.find<ApiClient>()), fenix: true);
    Get.lazyPut<AuthRepository>(() => AuthRepository(Get.find<AuthProvider>()), fenix: true);
    Get.lazyPut<CustomerProvider>(() => CustomerProvider(Get.find<ApiClient>()), fenix: true);
    Get.lazyPut<CustomerRepository>(() => CustomerRepository(Get.find<CustomerProvider>()), fenix: true);
    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
  }
}
