import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/core/network/api_client.dart';
import 'app/core/theme/app_theme.dart';
import 'app/data/services/storage_service.dart';
import 'app/modules/cart/controllers/cart_controller.dart';
import 'app/modules/wishlist/controllers/wishlist_controller.dart';
import 'app/routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Storage Service (GetStorage)
  final storageService = await StorageService().init();
  Get.put<StorageService>(storageService, permanent: true);

  // Initialize Network ApiClient (Dio)
  Get.put<ApiClient>(ApiClient(), permanent: true);

  // Initialize Cart & Wishlist Controllers
  Get.put<CartController>(CartController(), permanent: true);
  Get.put<WishlistController>(WishlistController(), permanent: true);

  runApp(const FoodOrderApp());
}

class FoodOrderApp extends StatelessWidget {
  const FoodOrderApp({super.key});

  @override
  Widget build(BuildContext context) {
    final storageService = Get.find<StorageService>();
    final isDarkMode = storageService.isDarkMode;

    return GetMaterialApp(
      title: 'Spice Haven - Food Ordering',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      defaultTransition: Transition.cupertino,
    );
  }
}
