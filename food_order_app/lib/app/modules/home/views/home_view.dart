import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../routes/app_routes.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/menu_item_model.dart';
import '../../cart/controllers/cart_controller.dart';
import '../../wishlist/controllers/wishlist_controller.dart';
import '../controllers/home_controller.dart';

import '../../../core/widgets/custom_bottom_nav_bar.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  IconData _getCategoryIcon(String categoryName) {
    final lower = categoryName.toLowerCase();
    if (lower.contains('starter') || lower.contains('appetizer'))
      return Icons.flatware_rounded;
    if (lower.contains('main')) return Icons.dinner_dining_rounded;
    if (lower.contains('italian') ||
        lower.contains('pizza') ||
        lower.contains('pasta')) return Icons.local_pizza_rounded;
    if (lower.contains('drink') || lower.contains('beverage'))
      return Icons.local_bar_rounded;
    if (lower.contains('dessert') || lower.contains('sweet'))
      return Icons.cake_rounded;
    return Icons.restaurant_menu_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 360;
    final CartController cartController = Get.find<CartController>();
    final WishlistController wishlistController = Get.find<WishlistController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => controller.loadDashboardData(),
            color: AppColors.primary,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Spice Haven Luxury Header Section
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                        isSmall ? 14 : 18, 44, isSmall ? 14 : 18, 20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF261208),
                          Color(0xFF3F1D0D),
                          Color(0xFF1C0C05),
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Brand Bar: Logo + Brand Name + Actions
                        Row(
                          children: [
                            // Circular Logo Emblem
                            Container(
                              width: isSmall ? 38 : 44,
                              height: isSmall ? 38 : 44,
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFDF7D),
                                    Color(0xFFD4AF37),
                                    Color(0xFF8C581E),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF9E1B).withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Container(
                                  color: const Color(0xFFFFFDF8),
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: isSmall ? 8 : 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'SPICE HAVEN',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.playfairDisplay(
                                      color: const Color(0xFFFFF7ED),
                                      fontSize: isSmall ? 15 : 18,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: isSmall ? 1.4 : 2.2,
                                    ),
                                  ),
                                  Text(
                                    'GOOD FOOD BRIGHTER DAYS',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFFFFD199),
                                      fontSize: isSmall ? 8.5 : 9.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: isSmall ? 1.0 : 1.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Quick Reservation Action
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => Get.toNamed(AppRoutes.reservation),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: isSmall ? 7 : 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD4AF37).withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFFD4AF37).withOpacity(0.4),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.table_restaurant_rounded,
                                        color: const Color(0xFFFFDF7D),
                                        size: isSmall ? 13 : 15,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Reserve',
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFFFFDF7D),
                                          fontSize: isSmall ? 10 : 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: isSmall ? 6 : 8),
                            // Wishlist Action
                            Obx(
                              () => Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => Get.toNamed(AppRoutes.wishlist),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: EdgeInsets.all(isSmall ? 7 : 9),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.12),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Icon(
                                          Icons.favorite_rounded,
                                          color: Colors.white,
                                          size: isSmall ? 18 : 20,
                                        ),
                                        if (wishlistController.wishlistItems.isNotEmpty)
                                          Positioned(
                                            top: -4,
                                            right: -4,
                                            child: Container(
                                              padding: const EdgeInsets.all(3),
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFE53935),
                                                shape: BoxShape.circle,
                                              ),
                                              constraints: const BoxConstraints(
                                                minWidth: 15,
                                                minHeight: 15,
                                              ),
                                              child: Text(
                                                '${wishlistController.wishlistItems.length}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 8.5,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Delivery Location Selector Bar
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => controller.openLocationSelectorSheet(),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFD4AF37).withOpacity(0.25),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD4AF37).withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.location_on_rounded,
                                      color: Color(0xFFFFD54F),
                                      size: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'DELIVERING TO:',
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFFFFDF7D),
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Obx(
                                      () => Text(
                                        controller.selectedOutlet.value,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Colors.white70,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Modern Rounded Pill Search Bar with Gold Accent & Soft Shadow
                        Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.2),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: controller.searchController,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2A1508),
                            ),
                            decoration: InputDecoration(
                              filled: false,
                              fillColor: Colors.transparent,
                              hintText:
                                  'Search gourmet starters, mains, desserts...',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.normal,
                              ),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(left: 6, right: 2),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.search_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                              ),
                              suffixIcon: Obx(
                                () => controller.searchQuery.value.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.cancel_rounded,
                                            color: Colors.grey, size: 20),
                                        onPressed: () =>
                                            controller.searchController.clear(),
                                      )
                                    : GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () => controller.openFilterSheet(),
                                        child: Padding(
                                          padding: const EdgeInsets.only(right: 6),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: controller.activeFilterCount > 0
                                                  ? AppColors.primary
                                                  : AppColors.primary.withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.tune_rounded,
                                              color: controller.activeFilterCount > 0
                                                  ? Colors.white
                                                  : AppColors.primary,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                          ),
                        ),

                        // Premium Food Search Suggestions Overlay
                        Obx(() {
                          final suggestions = controller.searchSuggestions;
                          if (controller.searchQuery.value.isEmpty ||
                              suggestions.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return Container(
                            margin: const EdgeInsets.only(top: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                itemCount: suggestions.length,
                                separatorBuilder: (context, index) => Divider(
                                    height: 1,
                                    color: Colors.grey.shade100,
                                    indent: 68,
                                    endIndent: 16),
                                itemBuilder: (context, index) {
                                  final item = suggestions[index];
                                  return InkWell(
                                    onTap: () {
                                      controller.searchController.text =
                                          item.name;
                                      controller.openFoodDetail(item);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 8),
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Image.network(
                                              item.imageUrl,
                                              width: 48,
                                              height: 48,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  Container(
                                                width: 48,
                                                height: 48,
                                                color: const Color(0xFFFBF6EB),
                                                child: const Icon(
                                                    Icons.fastfood_rounded,
                                                    size: 22,
                                                    color: AppColors.primary),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      width: 10,
                                                      height: 10,
                                                      margin:
                                                          const EdgeInsets.only(
                                                              right: 6),
                                                      decoration:
                                                          BoxDecoration(
                                                        border: Border.all(
                                                          color: item.isVeg
                                                              ? Colors.green
                                                              : Colors.red,
                                                          width: 1.5,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(2),
                                                      ),
                                                      child: Center(
                                                        child: Container(
                                                          width: 4,
                                                          height: 4,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: item.isVeg
                                                                ? Colors.green
                                                                : Colors.red,
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Text(
                                                        item.name,
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color:
                                                              Color(0xFF2A1508),
                                                        ),
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 3),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                        Icons.star_rounded,
                                                        size: 13,
                                                        color: Colors.amber),
                                                    const SizedBox(width: 3),
                                                    Text(
                                                      '${item.rating}',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Colors.grey.shade700,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      '•',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color:
                                                            Colors.grey.shade400,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      '₹${item.price.toStringAsFixed(0)}',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: AppColors
                                                            .primary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.north_west_rounded,
                                            size: 16,
                                            color: Colors.grey.shade400,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                // Spice Haven Signature Feature Banner
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        isSmall ? 12 : 18, 16, isSmall ? 12 : 18, 4),
                    child: Container(
                      padding: EdgeInsets.all(isSmall ? 14 : 18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF2C1307),
                            Color(0xFF4A200B),
                            Color(0xFF1E0C04),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFD4AF37).withOpacity(0.4),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF9E1B).withOpacity(0.18),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD4AF37).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'SPICE HAVEN EXCLUSIVES',
                                    style: GoogleFonts.outfit(
                                      fontSize: isSmall ? 8.5 : 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFFFFDF7D),
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Authentic Aromas,\nPure Culinary Art.',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: isSmall ? 16 : 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Wood-fired recipes & hand-ground spices',
                                  style: GoogleFonts.outfit(
                                    fontSize: isSmall ? 10 : 11,
                                    color: const Color(0xFFFFD199),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: isSmall ? 8 : 12),
                          Container(
                            width: isSmall ? 62 : 74,
                            height: isSmall ? 62 : 74,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFFFDF7D),
                                  Color(0xFFD4AF37),
                                  Color(0xFF8C581E),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Container(
                                color: const Color(0xFFFFFDF8),
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Chef Specials Carousel Section
                SliverToBoxAdapter(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return _buildShimmerSpecials();
                    }
                    if (controller.specialsList.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.local_fire_department_rounded,
                                      color: AppColors.primary, size: 22),
                                  SizedBox(width: 6),
                                  Text(
                                    "Chef's Specials",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF2A1508),
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Must Try',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 190,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: controller.specialsList.length,
                            itemBuilder: (context, index) {
                              final item = controller.specialsList[index];
                              return _buildSpecialCard(item, cartController);
                            },
                          ),
                        ),
                      ],
                    );
                  }),
                ),

                // Category Selector Sliver
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                        child: Text(
                          'Explore Categories',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2A1508),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      Obx(() {
                        if (controller.isLoading.value) {
                          return _buildShimmerCategories();
                        }
                        final selectedId = controller.selectedCategoryId.value;
                        return SizedBox(
                          height: 46,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: controller.categories.length,
                            itemBuilder: (context, index) {
                              final category = controller.categories[index];
                              final isSelected = selectedId == category.id;
                              return _buildCategoryChip(category, isSelected);
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                // Menu Items Header & Count
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        isSmall ? 14 : 20, 24, isSmall ? 14 : 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Obx(
                          () => Text(
                            'Dishes (${controller.filteredItems.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2A1508),
                            ),
                          ),
                        ),
                        Obx(
                          () {
                            final hasFilters = controller.activeFilterCount > 0;
                            return InkWell(
                              onTap: () => controller.openFilterSheet(),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: hasFilters
                                      ? AppColors.primary.withOpacity(0.1)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: hasFilters
                                        ? AppColors.primary
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.tune_rounded,
                                      size: 14,
                                      color: hasFilters
                                          ? AppColors.primary
                                          : Colors.grey.shade700,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      hasFilters
                                          ? 'Filtered (${controller.activeFilterCount})'
                                          : 'Filter & Sort',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: hasFilters
                                            ? AppColors.primary
                                            : Colors.grey.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Dishes List Section
                Obx(() {
                  if (controller.isLoading.value) {
                    return SliverToBoxAdapter(child: _buildShimmerFoodList());
                  }

                  if (controller.filteredItems.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.restaurant_menu_rounded,
                                    size: 48, color: AppColors.primary),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No Gourmet Dishes Found',
                                style: TextStyle(
                                    fontSize: 17,
                                    color: Color(0xFF2A1508),
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Try selecting another category or clear search.',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey.shade500),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                        isSmall ? 12 : 20, 0, isSmall ? 12 : 20, 110),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = controller.filteredItems[index];
                          return _buildFoodItemCard(item, cartController)
                              .animate()
                              .fadeIn(duration: 300.ms, delay: (index * 40).ms)
                              .slideY(
                                  begin: 0.1,
                                  end: 0,
                                  curve: Curves.easeOutQuad);
                        },
                        childCount: controller.filteredItems.length,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Floating Premium Cart Checkout Bar
          Obx(() {
            if (cartController.itemCount == 0) return const SizedBox.shrink();
            return Positioned(
              bottom: isSmall ? 12 : 20,
              left: isSmall ? 12 : 20,
              right: isSmall ? 12 : 20,
              child: GestureDetector(
                onTap: () => Get.toNamed(AppRoutes.cart),
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: isSmall ? 14 : 20, vertical: isSmall ? 10 : 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF261208), Color(0xFF3F1D0D)],
                    ),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withOpacity(0.5),
                      width: 1.2,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${cartController.itemCount} ${cartController.itemCount == 1 ? 'ITEM' : 'ITEMS'}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: isSmall ? 10 : 11,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            SizedBox(width: isSmall ? 8 : 12),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    AppFormatters.formatCurrency(
                                        cartController.grandTotal),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isSmall ? 14 : 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Taxes included',
                                    style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: isSmall ? 9 : 10),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Cart',
                            style: TextStyle(
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.bold,
                              fontSize: isSmall ? 12 : 14,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.arrow_forward_rounded,
                                color: Colors.white, size: isSmall ? 14 : 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().slideY(
                  begin: 1.2,
                  end: 0,
                  duration: 400.ms,
                  curve: Curves.easeOutBack);
          }),
        ],
      ),
    );
  }

  Widget _buildSpecialCard(MenuItemModel item, CartController cartController) {
    return GestureDetector(
      onTap: () => controller.openFoodDetail(item),
      child: Container(
        width: 270,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
          image: DecorationImage(
            image: NetworkImage(item.imageUrl),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.2),
                Colors.black.withOpacity(0.85),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFD4AF37), Color(0xFF8C581E)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'SPECIAL',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Colors.amber, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          '${item.rating}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          AppFormatters.formatCurrency(item.price),
                          style: const TextStyle(
                              color: AppColors.primaryLight,
                              fontSize: 15,
                              fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          if (item.modifierGroups.isNotEmpty) {
                            controller.openCustomizationSheet(item);
                          } else {
                            cartController.addToCart(item);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shopping_bag_outlined,
                                  size: 13, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text(
                                'Add to Cart',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(CategoryModel category, bool isSelected) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => controller.selectCategory(category.id),
      child: AnimatedContainer(
        key: ValueKey('category_${category.id}_$isSelected'),
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFD4AF37), // Rich Imperial Gold
                    Color(0xFFA07212), // Warm Deep Bronze
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: isSelected
              ? Border.all(color: const Color(0xFFFFDF7D), width: 1.5)
              : Border.all(color: const Color(0xFFE5DDD0), width: 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withOpacity(0.45),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getCategoryIcon(category.name),
              size: 16,
              color: isSelected ? Colors.white : AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              category.name,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF2A1508),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodItemCard(MenuItemModel item, CartController cartController) {
    final WishlistController wishlistController = Get.find<WishlistController>();
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = MediaQuery.of(context).size.width < 360;
        final imgDim = isCompact ? 86.0 : 100.0;
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => controller.openFoodDetail(item),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: EdgeInsets.all(isCompact ? 10.0 : 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dish Image & Badges
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          item.imageUrl,
                          width: imgDim,
                          height: imgDim,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: imgDim,
                            height: imgDim,
                            color: AppColors.primaryLight,
                            child: const Icon(Icons.restaurant,
                                color: AppColors.primary),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 4)
                            ],
                          ),
                          child: Icon(
                            Icons.circle,
                            size: 10,
                            color: item.isVeg
                                ? AppColors.vegGreen
                                : AppColors.nonVegRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: isCompact ? 10 : 14),

                  // Dish Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: isCompact ? 14 : 15,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2A1508),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: Colors.amber, size: 15),
                                const SizedBox(width: 2),
                                Text(
                                  '${item.rating}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2A1508),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Obx(() {
                                  final isFav =
                                      wishlistController.isWishlisted(item.id);
                                  return GestureDetector(
                                    onTap: () =>
                                        wishlistController.toggleWishlist(item),
                                    child: Icon(
                                      isFav
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                      color: isFav
                                          ? Colors.redAccent
                                          : Colors.grey.shade400,
                                      size: 20,
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              height: 1.3),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                AppFormatters.formatCurrency(item.price),
                                style: TextStyle(
                                  fontSize: isCompact ? 14 : 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            SizedBox(
                              height: 34,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  if (item.modifierGroups.isNotEmpty) {
                                    controller.openCustomizationSheet(item);
                                  } else {
                                    cartController.addToCart(item);
                                  }
                                },
                                icon: Icon(Icons.shopping_bag_outlined,
                                    size: isCompact ? 13 : 14,
                                    color: AppColors.primary),
                                label: Text(
                                  isCompact ? 'Add' : 'Add to Cart',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isCompact ? 11 : 12,
                                      color: AppColors.primary),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryLight,
                                  foregroundColor: AppColors.primary,
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: isCompact ? 8 : 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(
                                        color: AppColors.primary, width: 1.2),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerSpecials() {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(
        height: 180,
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
      ),
    );
  }

  Widget _buildShimmerCategories() {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: SizedBox(
        height: 46,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemBuilder: (_, __) => Container(
            width: 100,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(24)),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerFoodList() {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: 3,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemBuilder: (_, __) => Container(
          height: 110,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }
}
