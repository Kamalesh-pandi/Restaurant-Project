import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/menu_item_model.dart';
import '../../../data/providers/wishlist_provider.dart';
import '../../../data/repositories/wishlist_repository.dart';
import '../../../data/services/storage_service.dart';

class WishlistController extends GetxController {
  final RxList<MenuItemModel> wishlistItems = <MenuItemModel>[].obs;
  WishlistRepository? _wishlistRepository;

  @override
  void onInit() {
    super.onInit();
    _initRepository();
    _fetchBackendWishlist();
  }

  void _initRepository() {
    try {
      if (Get.isRegistered<ApiClient>()) {
        final apiClient = Get.find<ApiClient>();
        final provider = WishlistProvider(apiClient);
        _wishlistRepository = WishlistRepository(provider);
      }
    } catch (_) {}
  }

  Future<void> _fetchBackendWishlist() async {
    try {
      final phone = Get.isRegistered<StorageService>()
          ? Get.find<StorageService>().user?.phone
          : null;
      if (phone != null && phone.isNotEmpty && _wishlistRepository != null) {
        final backendItems = await _wishlistRepository!.getWishlist(phone);
        if (backendItems.isNotEmpty) {
          wishlistItems.assignAll(backendItems);
        }
      }
    } catch (_) {}
  }

  bool isWishlisted(String itemId) {
    return wishlistItems.any((item) => item.id == itemId);
  }

  void toggleWishlist(MenuItemModel item) async {
    final phone = Get.isRegistered<StorageService>()
        ? Get.find<StorageService>().user?.phone
        : null;

    if (isWishlisted(item.id)) {
      wishlistItems.removeWhere((i) => i.id == item.id);
      if (phone != null && phone.isNotEmpty && _wishlistRepository != null) {
        _wishlistRepository!.toggleWishlist(phone, item.id);
      }
      Get.snackbar(
        'Removed from Wishlist',
        '${item.name} has been removed from your favorites.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF2A1508),
        colorText: Colors.white,
        icon: const Icon(Icons.favorite_outline_rounded, color: Colors.grey),
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
        duration: const Duration(seconds: 2),
      );
    } else {
      wishlistItems.add(item);
      if (phone != null && phone.isNotEmpty && _wishlistRepository != null) {
        _wishlistRepository!.toggleWishlist(phone, item.id);
      }
      Get.snackbar(
        'Added to Wishlist',
        '${item.name} saved to your favorites!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF2A1508),
        colorText: Colors.white,
        icon: const Icon(Icons.favorite_rounded, color: Colors.redAccent),
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
        duration: const Duration(seconds: 2),
      );
    }
  }

  void removeFromWishlist(MenuItemModel item) {
    if (isWishlisted(item.id)) {
      toggleWishlist(item);
    }
  }

  void clearWishlist() {
    wishlistItems.clear();
    Get.snackbar(
      'Wishlist Cleared',
      'All saved items have been removed.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFF2A1508),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
    );
  }
}
