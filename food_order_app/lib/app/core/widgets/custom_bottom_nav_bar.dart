import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../modules/cart/controllers/cart_controller.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    CartController? cartController;
    try {
      cartController = Get.find<CartController>();
    } catch (_) {}

    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 360;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFD4AF37).withOpacity(0.25),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 6 : 10,
            vertical: isCompact ? 6 : 8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.restaurant_menu_rounded,
                label: 'Menu',
                route: AppRoutes.home,
                isCompact: isCompact,
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.table_restaurant_rounded,
                label: 'Reserve',
                route: AppRoutes.reservation,
                isCompact: isCompact,
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.shopping_bag_rounded,
                label: 'Cart',
                route: AppRoutes.cart,
                isCart: true,
                cartController: cartController,
                isCompact: isCompact,
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.track_changes_rounded,
                label: 'Tracking',
                route: AppRoutes.tracking,
                isCompact: isCompact,
              ),
              _buildNavItem(
                index: 4,
                icon: Icons.person_rounded,
                label: 'Profile',
                route: AppRoutes.profile,
                isCompact: isCompact,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required String route,
    bool isCart = false,
    CartController? cartController,
    bool isCompact = false,
  }) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          if (route == AppRoutes.home) {
            Get.offAllNamed(route);
          } else {
            Get.toNamed(route);
          }
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? (isCompact ? 8 : 14) : (isCompact ? 6 : 10),
          vertical: isCompact ? 6 : 7,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [
                    Color(0xFF2A1206),
                    Color(0xFF451E0C),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(
                  color: const Color(0xFFD4AF37).withOpacity(0.6),
                  width: 1,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isSelected ? const Color(0xFFFFDF7D) : const Color(0xFF8A766B),
                  size: isCompact ? 19 : 21,
                ),
                if (isCart && cartController != null)
                  Obx(() {
                    final count = cartController.cartItems.fold<int>(0, (sum, i) => sum + i.quantity);
                    if (count == 0) return const SizedBox.shrink();
                    return Positioned(
                      top: -6,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            color: isSelected ? AppColors.primary : Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ).animate().scale(duration: 200.ms, curve: Curves.easeOut),
                    );
                  }),
              ],
            ),
            if (isSelected) ...[
              SizedBox(width: isCompact ? 5 : 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isCompact ? 11 : 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
