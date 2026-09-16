import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_dialogs.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/order_model.dart';
import '../../../routes/app_routes.dart';
import '../controllers/cart_controller.dart';

import '../../../core/widgets/custom_bottom_nav_bar.dart';

class CartView extends GetView<CartController> {
  const CartView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 2),
      body: Column(
        children: [
          // Custom AppBar with gradient
          Container(
            padding: const EdgeInsets.fromLTRB(8, 48, 16, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF261208), Color(0xFF3F1D0D), Color(0xFF1C0C05)],
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
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                  onPressed: () => Get.back(),
                ),
                const Expanded(
                  child: Text(
                    'Your Spice Haven Cart',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                ),
                Obx(
                  () => controller.cartItems.isNotEmpty
                      ? GestureDetector(
                          onTap: () => controller.clearCart(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.delete_outline_rounded,
                                color: Colors.redAccent, size: 20),
                          ),
                        )
                      : const SizedBox(width: 40),
                ),
              ],
            ),
          ),

          Expanded(
            child: Obx(() {
              if (controller.cartItems.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.12),
                                AppColors.primary.withOpacity(0.04)
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shopping_bag_outlined,
                              size: 68, color: AppColors.primary),
                        ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                              begin: const Offset(0.95, 0.95),
                              end: const Offset(1.05, 1.05),
                              duration: 1500.ms,
                              curve: Curves.easeInOut,
                            ),
                        const SizedBox(height: 24),
                        const Text(
                          'Your Cart is Empty',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2A1508)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Explore our artisan menu and add your favorite gourmet dishes.',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade500),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        GestureDetector(
                          onTap: () => Get.offAllNamed(AppRoutes.home),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                Color(0xFFD4AF37),
                                Color(0xFFA07212)
                              ]),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.restaurant_menu_rounded,
                                    color: Colors.white, size: 18),
                                SizedBox(width: 10),
                                Text(
                                  'Explore Menu',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 400.ms).scale(
                        begin: const Offset(0.9, 0.9), curve: Curves.easeOut),
                  ),
                );
              }

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Type Selector
                    Container(
                      padding: const EdgeInsets.all(18.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.two_wheeler_rounded,
                                  color: AppColors.primary, size: 22),
                              SizedBox(width: 10),
                              Text(
                                'Order Fulfillment',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF2A1508)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Obx(
                            () => Row(
                              children: [
                                _buildOrderTypeChoice(
                                    OrderType.delivery, 'Delivery', '🚚'),
                                const SizedBox(width: 8),
                                _buildOrderTypeChoice(
                                    OrderType.takeaway, 'Takeaway', '🛍️'),
                                const SizedBox(width: 8),
                                _buildOrderTypeChoice(
                                    OrderType.dineIn, 'Dine-In', '🍽️'),
                              ],
                            ),
                          ),
                          Obx(
                            () => controller.selectedOrderType.value ==
                                    OrderType.dineIn
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 14),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                            color: AppColors.primary
                                                .withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                              Icons.qr_code_scanner_rounded,
                                              color: AppColors.primary,
                                              size: 22),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              controller.dineInTable.value
                                                      .isNotEmpty
                                                  ? 'Assigned: ${controller.dineInTable.value}'
                                                  : 'Tap to set Dine-in Table Number',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primary,
                                                  fontSize: 13),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                               final tableInputCtrl = TextEditingController();
                                               AppDialogs.custom(
                                                 title: 'Dine-in Table',
                                                 icon: Icons.table_restaurant_rounded,
                                                 content: Column(
                                                   mainAxisSize: MainAxisSize.min,
                                                   children: [
                                                     Text(
                                                       'Please enter your table number to serve your order directly to your seat.',
                                                       textAlign: TextAlign.center,
                                                       style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                                     ),
                                                     const SizedBox(height: 16),
                                                     TextField(
                                                       controller: tableInputCtrl,
                                                       autofocus: true,
                                                       keyboardType: TextInputType.text,
                                                       decoration: InputDecoration(
                                                         hintText: 'e.g. Table 5, T2, Outdoor 3',
                                                         prefixIcon: const Icon(
                                                           Icons.tag_rounded,
                                                           color: AppColors.primary,
                                                         ),
                                                         border: OutlineInputBorder(
                                                           borderRadius: BorderRadius.circular(14),
                                                         ),
                                                       ),
                                                     ),
                                                   ],
                                                 ),
                                                 actions: [
                                                   TextButton(
                                                     onPressed: () => Get.back(),
                                                     style: TextButton.styleFrom(
                                                       padding: const EdgeInsets.symmetric(vertical: 12),
                                                     ),
                                                     child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                                                   ),
                                                   ElevatedButton(
                                                     onPressed: () {
                                                       final val = tableInputCtrl.text.trim();
                                                       if (val.isNotEmpty) {
                                                         controller.dineInTable.value = val.startsWith('Table') ? val : 'Table $val';
                                                       }
                                                       Get.back();
                                                     },
                                                     style: ElevatedButton.styleFrom(
                                                       backgroundColor: AppColors.primary,
                                                       foregroundColor: Colors.white,
                                                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                       padding: const EdgeInsets.symmetric(vertical: 12),
                                                     ),
                                                     child: const Text('Set Table'),
                                                   ),
                                                 ],
                                               );
                                             },
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 7),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: const Text('Set Table',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                      fontSize: 12)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        .animate()
                                        .fadeIn(duration: 300.ms)
                                        .slideY(begin: -0.1, end: 0),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 350.ms),

                    const SizedBox(height: 24),

                    const Text('Selected Dishes',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2A1508))),
                    const SizedBox(height: 14),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: controller.cartItems.length,
                      itemBuilder: (context, index) {
                        final cartItem = controller.cartItems[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(14.0),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.network(
                                      cartItem.item.imageUrl,
                                      width: 68,
                                      height: 68,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 68,
                                        height: 68,
                                        color: AppColors.primaryLight,
                                        child: const Icon(Icons.restaurant,
                                            color: AppColors.primary),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cartItem.item.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: Color(0xFF2A1508)),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          AppFormatters.formatCurrency(
                                              cartItem.unitPrice),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Stepper
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      children: [
                                        InkWell(
                                          onTap: () => controller
                                              .decrementQuantity(index),
                                          borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(14),
                                              bottomLeft: Radius.circular(14)),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                            child: Icon(Icons.remove_rounded,
                                                size: 16,
                                                color: AppColors.primary),
                                          ),
                                        ),
                                        Text(
                                          '${cartItem.quantity}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: Color(0xFF2A1508)),
                                        ),
                                        InkWell(
                                          onTap: () => controller
                                              .incrementQuantity(index),
                                          borderRadius: const BorderRadius.only(
                                              topRight: Radius.circular(14),
                                              bottomRight: Radius.circular(14)),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                            child: Icon(Icons.add_rounded,
                                                size: 16,
                                                color: AppColors.primary),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (cartItem.selectedModifiers.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: cartItem.selectedModifiers.map((m) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '+ ${m.name} (${AppFormatters.formatCurrency(m.extraPrice)})',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(
                                duration: 250.ms,
                                delay: Duration(milliseconds: index * 60))
                            .slideX(begin: -0.05, end: 0);
                      },
                    ),

                    // Coupon Box
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.local_offer_rounded,
                                color: AppColors.primary, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: controller.couponTextController,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                              decoration: const InputDecoration(
                                hintText: 'Enter Promo Code (e.g. GOURMET50)',
                                hintStyle:
                                    TextStyle(fontSize: 12, color: Colors.grey),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              if (controller.couponTextController.text.trim().isNotEmpty) {
                                controller.applyCoupon(
                                    controller.couponTextController.text.trim());
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [
                                  Color(0xFFD4AF37),
                                  Color(0xFFA07212)
                                ]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text('APPLY',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Bill Details
                    Container(
                      padding: const EdgeInsets.all(22.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.receipt_long_rounded,
                                    color: AppColors.primary, size: 18),
                              ),
                              const SizedBox(width: 10),
                              const Text('Bill Summary',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF2A1508))),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 12),
                          _buildBillRow(
                              'Item Subtotal',
                              AppFormatters.formatCurrency(
                                  controller.subtotal)),
                          const SizedBox(height: 10),
                          _buildBillRow(
                              'GST Taxes (5%)',
                              AppFormatters.formatCurrency(
                                  controller.gstAmount)),
                          const SizedBox(height: 10),
                          _buildBillRow(
                            'Delivery & Packaging Fee',
                            controller.deliveryFee == 0
                                ? 'FREE'
                                : AppFormatters.formatCurrency(
                                    controller.deliveryFee),
                            isFree: controller.deliveryFee == 0,
                          ),
                          Obx(
                            () => controller.couponDiscount.value > 0
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: _buildBillRow(
                                      'Promo Coupon Discount',
                                      '- ${AppFormatters.formatCurrency(controller.couponDiscount.value)}',
                                      isDiscount: true,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('To Pay',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                      color: Color(0xFF2A1508))),
                              Obx(
                                () => Text(
                                  AppFormatters.formatCurrency(
                                      controller.grandTotal),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 22,
                                      color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.05, end: 0),

                    const SizedBox(height: 28),

                    // CTA Button
                    GestureDetector(
                      onTap: () => Get.toNamed(AppRoutes.payment),
                      child: Container(
                        width: double.infinity,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFFD4AF37), Color(0xFFA07212)]),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.45),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.lock_outline_rounded,
                                  color: Colors.white, size: 20),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Obx(
                                  () => Text(
                                    'Proceed to Pay ${AppFormatters.formatCurrency(controller.grandTotal)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().shimmer(
                        duration: 1200.ms,
                        delay: 800.ms,
                        color: Colors.white.withOpacity(0.3)),

                    const SizedBox(height: 32),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTypeChoice(OrderType type, String label, String emoji) {
    final isSelected = controller.selectedOrderType.value == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.selectedOrderType.value = type,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF261208), Color(0xFF451E0C)])
                : null,
            color: isSelected ? null : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
            border: isSelected
                ? Border.all(color: const Color(0xFFD4AF37), width: 1.2)
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBillRow(String label, String value,
      {bool isFree = false, bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: isDiscount ? AppColors.success : Colors.grey.shade600,
                fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            color: isFree || isDiscount
                ? AppColors.success
                : const Color(0xFF2A1508),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
