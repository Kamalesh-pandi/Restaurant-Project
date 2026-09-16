import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/home_controller.dart';

class FoodFilterBottomSheet extends StatelessWidget {
  const FoodFilterBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.find<HomeController>();

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.tune_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filter & Sort Menu',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2A1508),
                          ),
                        ),
                        Text(
                          'Refine dishes by diet, price, rating & more',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => controller.resetFilters(),
                    child: const Text(
                      'Reset All',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Dietary Preference
                    const Text(
                      'DIETARY PREFERENCE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Obx(
                      () => Row(
                        children: [
                          _buildChoiceChip(
                            label: 'All Items',
                            isSelected: controller.selectedVegFilter.value == 'all',
                            onTap: () {
                              controller.selectedVegFilter.value = 'all';
                              controller.filterMenu();
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildChoiceChip(
                            label: 'Pure Veg 🌱',
                            isSelected: controller.selectedVegFilter.value == 'veg',
                            onTap: () {
                              controller.selectedVegFilter.value = 'veg';
                              controller.filterMenu();
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildChoiceChip(
                            label: 'Non-Veg 🍗',
                            isSelected: controller.selectedVegFilter.value == 'non_veg',
                            onTap: () {
                              controller.selectedVegFilter.value = 'non_veg';
                              controller.filterMenu();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 2. Sort By
                    const Text(
                      'SORT DISHES BY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Obx(
                      () => Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildChoiceChip(
                            label: 'Top Rated ⭐',
                            isSelected: controller.selectedSortOption.value == 'rating',
                            onTap: () {
                              controller.selectedSortOption.value = 'rating';
                              controller.filterMenu();
                            },
                          ),
                          _buildChoiceChip(
                            label: 'Price: Low to High ⬇️',
                            isSelected: controller.selectedSortOption.value == 'price_low',
                            onTap: () {
                              controller.selectedSortOption.value = 'price_low';
                              controller.filterMenu();
                            },
                          ),
                          _buildChoiceChip(
                            label: 'Price: High to Low ⬆️',
                            isSelected: controller.selectedSortOption.value == 'price_high',
                            onTap: () {
                              controller.selectedSortOption.value = 'price_high';
                              controller.filterMenu();
                            },
                          ),
                          _buildChoiceChip(
                            label: 'Name A-Z 🔤',
                            isSelected: controller.selectedSortOption.value == 'name',
                            onTap: () {
                              controller.selectedSortOption.value = 'name';
                              controller.filterMenu();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 3. Price Range Filter
                    const Text(
                      'PRICE RANGE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Obx(
                      () => Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildChoiceChip(
                            label: 'All Prices',
                            isSelected: controller.selectedPriceRange.value == 'all',
                            onTap: () {
                              controller.selectedPriceRange.value = 'all';
                              controller.filterMenu();
                            },
                          ),
                          _buildChoiceChip(
                            label: 'Under ₹200',
                            isSelected: controller.selectedPriceRange.value == 'under_200',
                            onTap: () {
                              controller.selectedPriceRange.value = 'under_200';
                              controller.filterMenu();
                            },
                          ),
                          _buildChoiceChip(
                            label: '₹200 - ₹500',
                            isSelected: controller.selectedPriceRange.value == '200_500',
                            onTap: () {
                              controller.selectedPriceRange.value = '200_500';
                              controller.filterMenu();
                            },
                          ),
                          _buildChoiceChip(
                            label: 'Above ₹500',
                            isSelected: controller.selectedPriceRange.value == 'above_500',
                            onTap: () {
                              controller.selectedPriceRange.value = 'above_500';
                              controller.filterMenu();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 4. Chef Specials Only Toggle
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBF6EB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.35)),
                      ),
                      child: Obx(
                        () => SwitchListTile(
                          activeColor: AppColors.primary,
                          title: const Row(
                            children: [
                              Text(
                                'Chef\'s Specials Only',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2A1508),
                                ),
                              ),
                              SizedBox(width: 6),
                              Text('🔥', style: TextStyle(fontSize: 16)),
                            ],
                          ),
                          subtitle: const Text(
                            'Show only signature handcrafted gourmet dishes',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          value: controller.isSpecialsOnly.value,
                          onChanged: (val) {
                            controller.isSpecialsOnly.value = val;
                            controller.filterMenu();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Apply Button Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Apply Filters (${controller.filteredItems.length} Dishes Found)',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey.shade800,
          ),
        ),
      ),
    );
  }
}
