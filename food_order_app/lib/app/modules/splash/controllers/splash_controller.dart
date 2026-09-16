import 'package:get/get.dart';
import '../../../data/services/storage_service.dart';
import '../../../routes/app_routes.dart';

class SplashController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() async {
    // Wait for splash animation / screen display
    await Future.delayed(const Duration(milliseconds: 2600));

    final storageService = Get.find<StorageService>();
    final isLoggedIn = storageService.token != null && storageService.token!.isNotEmpty;

    if (isLoggedIn) {
      Get.offAllNamed(AppRoutes.home);
    } else {
      Get.offAllNamed(AppRoutes.auth);
    }
  }
}
