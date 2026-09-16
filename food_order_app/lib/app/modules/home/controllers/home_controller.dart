import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/snackbars.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/menu_item_model.dart';
import '../../../data/repositories/menu_repository.dart';
import '../../../data/services/storage_service.dart';
import '../../../routes/app_routes.dart';
import '../../cart/controllers/cart_controller.dart';
import '../../food_detail/widgets/customization_bottom_sheet.dart';
import '../widgets/location_selector_sheet.dart';

import '../widgets/food_filter_bottom_sheet.dart';

class HomeController extends GetxController {
  final MenuRepository _menuRepository = Get.find<MenuRepository>();
  final StorageService _storageService = Get.find<StorageService>();

  final RxBool isLoading = true.obs;
  final RxString selectedOutlet = ''.obs;
  final RxBool isDetectingLocation = false.obs;

  // Filter & Sort State
  final RxString selectedVegFilter = 'all'.obs; // 'all', 'veg', 'non_veg'
  final RxString selectedSortOption = 'rating'.obs; // 'rating', 'price_low', 'price_high', 'name'
  final RxString selectedPriceRange = 'all'.obs; // 'all', 'under_200', '200_500', 'above_500'
  final RxBool isSpecialsOnly = false.obs;

  int get activeFilterCount {
    int count = 0;
    if (selectedVegFilter.value != 'all') count++;
    if (selectedSortOption.value != 'rating') count++;
    if (selectedPriceRange.value != 'all') count++;
    if (isSpecialsOnly.value) count++;
    return count;
  }

  void resetFilters() {
    selectedVegFilter.value = 'all';
    selectedSortOption.value = 'rating';
    selectedPriceRange.value = 'all';
    isSpecialsOnly.value = false;
    filterMenu();
  }

  void openFilterSheet() {
    Get.bottomSheet(
      const FoodFilterBottomSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void filterMenu() {
    List<MenuItemModel> temp = List.from(allMenuItems);

    // 1. Category Filter
    if (selectedCategoryId.value != 'all' && selectedCategoryId.value.isNotEmpty) {
      final selectedCat = categories.firstWhereOrNull((c) => c.id == selectedCategoryId.value);
      temp = temp.where((item) {
        if (item.categoryId == selectedCategoryId.value) return true;
        if (selectedCat != null &&
            (item.categoryId.toLowerCase() == selectedCat.name.toLowerCase() ||
             selectedCat.id.toLowerCase() == item.categoryId.toLowerCase())) {
          return true;
        }
        return false;
      }).toList();
    }

    // 2. Search Query Filter
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      temp = temp
          .where((item) =>
              item.name.toLowerCase().contains(query) ||
              item.description.toLowerCase().contains(query))
          .toList();
    }

    // 3. Veg / Non-Veg Filter
    if (selectedVegFilter.value == 'veg') {
      temp = temp.where((item) => item.isVeg == true).toList();
    } else if (selectedVegFilter.value == 'non_veg') {
      temp = temp.where((item) => item.isVeg == false).toList();
    }

    // 4. Price Range Filter
    if (selectedPriceRange.value == 'under_200') {
      temp = temp.where((item) => item.price < 200).toList();
    } else if (selectedPriceRange.value == '200_500') {
      temp = temp.where((item) => item.price >= 200 && item.price <= 500).toList();
    } else if (selectedPriceRange.value == 'above_500') {
      temp = temp.where((item) => item.price > 500).toList();
    }

    // 5. Chef Specials Only Filter
    if (isSpecialsOnly.value) {
      temp = temp.where((item) => item.isSpecial == true).toList();
    }

    // 6. Sorting
    if (selectedSortOption.value == 'price_low') {
      temp.sort((a, b) => a.price.compareTo(b.price));
    } else if (selectedSortOption.value == 'price_high') {
      temp.sort((a, b) => b.price.compareTo(a.price));
    } else if (selectedSortOption.value == 'name') {
      temp.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else {
      // Default: Highest Rating
      temp.sort((a, b) => b.rating.compareTo(a.rating));
    }

    filteredItems.assignAll(temp);
  }

  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final RxString selectedCategoryId = 'all'.obs;

  final RxList<MenuItemModel> allMenuItems = <MenuItemModel>[].obs;
  final RxList<MenuItemModel> specialsList = <MenuItemModel>[].obs;
  final RxList<MenuItemModel> filteredItems = <MenuItemModel>[].obs;

  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    final dbAddress = _storageService.user?.address;
    final savedOutlet = _storageService.selectedOutlet;

    if (dbAddress != null && dbAddress.trim().isNotEmpty) {
      selectedOutlet.value = dbAddress.trim();
    } else if (savedOutlet != null && savedOutlet.isNotEmpty) {
      selectedOutlet.value = savedOutlet;
    } else {
      selectedOutlet.value = 'Main Dining & Delivery Area';
    }

    _syncWithCartController(selectedOutlet.value);

    loadDashboardData();
    searchController.addListener(() {
      searchQuery.value = searchController.text.trim();
      filterMenu();
    });
  }

  void _syncWithCartController(String address) {
    try {
      if (Get.isRegistered<CartController>()) {
        Get.find<CartController>().deliveryAddress.value = address;
      }
    } catch (_) {}
  }

  void selectOutlet(String address) {
    final trimmed = address.trim();
    if (trimmed.isEmpty) return;
    selectedOutlet.value = trimmed;
    _storageService.saveSelectedOutlet(trimmed);
    _syncWithCartController(trimmed);

    AppSnackbars.showSuccess(
      title: 'Delivery Location Set',
      message: 'Food will be delivered to: $trimmed',
    );
  }

  Future<void> detectCurrentLocation() async {
    isDetectingLocation.value = true;
    await Future.delayed(const Duration(milliseconds: 1000));
    isDetectingLocation.value = false;
    selectOutlet('Current GPS Location (Detected)');
  }

  void openLocationSelectorSheet() {
    Get.bottomSheet(
      const LocationSelectorSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Future<void> loadDashboardData() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _menuRepository.getCategories(),
        _menuRepository.getSpecials(),
        _menuRepository.getMenuItems(),
      ]);

      categories.assignAll(results[0] as List<CategoryModel>);
      specialsList.assignAll(results[1] as List<MenuItemModel>);
      allMenuItems.assignAll(results[2] as List<MenuItemModel>);

      filterMenu();
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void selectCategory(String categoryId) {
    if (selectedCategoryId.value == categoryId && categoryId != 'all') {
      selectedCategoryId.value = 'all';
    } else {
      selectedCategoryId.value = categoryId;
    }
    filterMenu();
  }

  List<MenuItemModel> get searchSuggestions {
    if (searchQuery.value.trim().isEmpty) return [];
    final query = searchQuery.value.trim().toLowerCase();
    return allMenuItems
        .where((item) =>
            item.name.toLowerCase().contains(query) ||
            item.description.toLowerCase().contains(query))
        .take(6)
        .toList();
  }



  void openFoodDetail(MenuItemModel item) {
    Get.toNamed(AppRoutes.foodDetail, arguments: item);
  }

  Future<void> openCustomizationSheet(MenuItemModel item) async {
    final modifierGroups = await _menuRepository.getModifierGroups(item.id);
    Get.bottomSheet(
      CustomizationBottomSheet(
        item: item,
        modifierGroups: modifierGroups,
      ),
      isScrollControlled: true,
    );
  }

  @override
  void onClose() {
    searchController.clear();
    super.onClose();
  }
}
