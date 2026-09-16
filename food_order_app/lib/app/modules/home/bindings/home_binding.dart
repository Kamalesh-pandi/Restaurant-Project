import 'package:get/get.dart';
import '../../../data/providers/menu_provider.dart';
import '../../../data/repositories/menu_repository.dart';
import '../../../core/network/api_client.dart';
import '../controllers/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MenuProvider>(() => MenuProvider(Get.find<ApiClient>()), fenix: true);
    Get.lazyPut<MenuRepository>(() => MenuRepository(Get.find<MenuProvider>()), fenix: true);
    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);
  }
}
