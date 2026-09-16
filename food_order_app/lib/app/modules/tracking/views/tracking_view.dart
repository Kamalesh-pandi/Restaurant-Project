import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/order_model.dart';
import '../../../routes/app_routes.dart';
import '../controllers/tracking_controller.dart';
import '../../../core/widgets/custom_bottom_nav_bar.dart';

class TrackingView extends GetView<TrackingController> {
  const TrackingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 3),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(8, 48, 16, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
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
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Get.back();
                    } else {
                      Get.offAllNamed(AppRoutes.home);
                    }
                  },
                ),
                const Expanded(
                  child: Text(
                    'Live Order Status',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                ),
                // Switch Order Button
                GestureDetector(
                  onTap: () => _showOrderSwitcherSheet(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.swap_horiz_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
                // Home Button
                GestureDetector(
                  onTap: () => Get.offAllNamed(AppRoutes.home),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.home_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // Active Orders Selector Strip (when multiple active orders exist)
          Obx(() {
            final activeList = controller.activeOrders;
            if (activeList.length <= 1) return const SizedBox.shrink();

            return Container(
              margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00C853),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${activeList.length} Live Orders Active',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2A1508),
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'Tap to switch live view',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 74,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: activeList.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (ctx, idx) {
                        final ord = activeList[idx];
                        final isSelected = ord.id == controller.orderId.value;
                        final shortId = (ord.id != null && ord.id!.length > 8)
                            ? ord.id!.substring(0, 8)
                            : (ord.id ?? 'Order');

                        Color badgeColor = AppColors.warning;
                        String statusLabel = ord.orderStatus;
                        final s = ord.orderStatus.toLowerCase();
                        if (s.contains('delivery') || s.contains('route')) {
                          badgeColor = const Color(0xFF8B5CF6);
                          statusLabel = 'On the way';
                        } else if (s.contains('served')) {
                          badgeColor = AppColors.success;
                          statusLabel = ord.orderType == OrderType.dineIn
                              ? 'Served at Table'
                              : (ord.orderType == OrderType.takeaway
                                  ? 'Served / Ready'
                                  : 'Food Served');
                        } else if (s.contains('ready')) {
                          badgeColor = const Color(0xFF10B981);
                          statusLabel = 'Food Ready';
                        } else if (s.contains('prep') || s.contains('kitchen')) {
                          badgeColor = const Color(0xFFFF9800);
                          statusLabel = 'Cooking';
                        } else if (s.contains('placed') || s.contains('new')) {
                          badgeColor = const Color(0xFF2563EB);
                          statusLabel = 'Placed';
                        } else if (s.contains('delivered') || s.contains('completed')) {
                          badgeColor = AppColors.success;
                          statusLabel = 'Delivered';
                        }

                        return GestureDetector(
                          onTap: () => controller.selectOrder(ord.id!),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: 180,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFFFF7ED)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : const Color(0xFFE2E8F0),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withOpacity(0.18),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 2.5),
                                      decoration: BoxDecoration(
                                        color: badgeColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        statusLabel,
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: badgeColor,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(Icons.check_circle_rounded,
                                          color: AppColors.primary, size: 16),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '#$shortId',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? AppColors.primary
                                            : const Color(0xFF2A1508),
                                      ),
                                    ),
                                    Text(
                                      AppFormatters.formatCurrency(
                                          ord.grandTotal),
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }),

          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              final timeline = controller.timelineData.value;
              if (timeline == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off_rounded,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Order tracking data unavailable',
                          style: TextStyle(fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 12),
                      Text(
                        'Order ID: ${controller.orderId.value}',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => Get.offAllNamed(AppRoutes.home),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Back to Home',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              }

              final hasAssignedPartner = timeline.partnerName != null &&
                  timeline.partnerName!.trim().isNotEmpty;
              final partnerName = timeline.partnerName ?? '';
              final partnerPhone = timeline.partnerPhone;
              final partnerVehicle = timeline.partnerVehicleNumber;
              final deliveryOtp = timeline.deliveryOtp;

              return Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: () => controller.loadAllOrdersAndTimeline(
                      preferredOrderId: controller.orderId.value,
                      showLoading: false,
                    ),
                    color: AppColors.primary,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Order Card (Overflow Protected)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF261208), Color(0xFF3F1D0D)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFFD4AF37).withOpacity(0.35),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Obx(() => Text(
                                              'Order #${controller.orderId.value}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 17,
                                                color: Colors.white,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            )),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Spice Haven – Flagship',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white.withOpacity(0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      gradient: (timeline.currentStatus.toUpperCase() == 'SERVED' ||
                                              timeline.currentStatus.toUpperCase() == 'READY' ||
                                              timeline.currentStatus.toUpperCase() == 'DELIVERED')
                                          ? const LinearGradient(colors: [
                                              Color(0xFF00C853),
                                              Color(0xFF009624),
                                            ])
                                          : (timeline.currentStatus.toUpperCase() == 'ASSIGNED' ||
                                                  timeline.currentStatus.toUpperCase() == 'OUT_FOR_DELIVERY' ||
                                                  timeline.currentStatus.toUpperCase() == 'ON_DELIVERY')
                                              ? const LinearGradient(colors: [
                                                  Color(0xFF0284C7),
                                                  Color(0xFF0369A1),
                                                ])
                                              : const LinearGradient(colors: [
                                                  Color(0xFFD4AF37),
                                                  Color(0xFFA07212),
                                                ]),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (timeline.currentStatus.toUpperCase() == 'SERVED' ||
                                                  timeline.currentStatus.toUpperCase() == 'READY' ||
                                                  timeline.currentStatus.toUpperCase() == 'DELIVERED')
                                              ? const Color(0xFF00C853)
                                                  .withOpacity(0.4)
                                              : (timeline.currentStatus.toUpperCase() == 'ASSIGNED' ||
                                                      timeline.currentStatus.toUpperCase() == 'OUT_FOR_DELIVERY')
                                                  ? const Color(0xFF0284C7)
                                                      .withOpacity(0.4)
                                                  : AppColors.primary
                                                      .withOpacity(0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      timeline.statusDisplay,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Divider(
                                  height: 28,
                                  color: Colors.white.withOpacity(0.25)),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.timer_rounded,
                                        color: Colors.white, size: 24),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Estimated Delivery',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.8),
                                            fontSize: 11,
                                          ),
                                        ),
                                        Text(
                                          timeline.estimatedDeliveryTime,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (deliveryOtp != null && deliveryOtp.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.18),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.key_rounded,
                                              color: Colors.amber, size: 14),
                                          const SizedBox(width: 4),
                                          Text(
                                            'OTP: $deliveryOtp',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 350.ms),
                        const SizedBox(height: 20),

                        // Delivery Partner Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.primary.withOpacity(0.15)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: hasAssignedPartner
                              ? Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.delivery_dining_rounded,
                                        color: AppColors.primary,
                                        size: 26,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                partnerName,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF2A1508),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              const Icon(Icons.star_rounded,
                                                  color: Colors.amber, size: 14),
                                              const Text(
                                                '5.0',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                          if (partnerVehicle != null && partnerVehicle.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              partnerVehicle,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (partnerPhone != null && partnerPhone.isNotEmpty)
                                      IconButton(
                                        onPressed: () {
                                          Get.snackbar(
                                            'Calling Delivery Partner',
                                            'Dialing $partnerName ($partnerPhone)...',
                                            snackPosition: SnackPosition.TOP,
                                            backgroundColor: const Color(0xFF2A1508),
                                            colorText: Colors.white,
                                            icon: const Icon(
                                                Icons.phone_in_talk_rounded,
                                                color: AppColors.primary),
                                            margin: const EdgeInsets.all(16),
                                            borderRadius: 14,
                                          );
                                        },
                                        icon: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: const BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.call_rounded,
                                              color: Colors.white, size: 16),
                                        ),
                                      ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFC59B27).withOpacity(0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.access_time_filled_rounded,
                                        color: Color(0xFFC59B27),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Assigning Delivery Partner',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF2A1508),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'A rider will be assigned once order is ready',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 24),

                        const Text(
                          'Preparation & Delivery Timeline',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2A1508)),
                        ),
                        const SizedBox(height: 14),

                        // Stepper Card with IntrinsicHeight
                        Container(
                          padding: const EdgeInsets.all(20.0),
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
                            children:
                                List.generate(timeline.stages.length, (index) {
                              final stage = timeline.stages[index];
                              final isLast = index == timeline.stages.length - 1;

                              return IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      children: [
                                        AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: stage.isCompleted ||
                                                    stage.isCurrent
                                                ? const LinearGradient(colors: [
                                                    Color(0xFFD4AF37),
                                                    Color(0xFFA07212)
                                                  ])
                                                : null,
                                            color: stage.isCompleted ||
                                                    stage.isCurrent
                                                ? null
                                                : Colors.grey.shade200,
                                            boxShadow: stage.isCurrent
                                                ? [
                                                    BoxShadow(
                                                      color: AppColors.primary
                                                          .withOpacity(0.4),
                                                      blurRadius: 10,
                                                      offset:
                                                          const Offset(0, 3),
                                                    ),
                                                  ]
                                                : [],
                                          ),
                                          child: Icon(
                                            stage.isCompleted
                                                ? Icons.check_rounded
                                                : (stage.isCurrent
                                                    ? Icons
                                                        .restaurant_menu_rounded
                                                    : Icons.circle_outlined),
                                            size: 16,
                                            color: stage.isCompleted ||
                                                    stage.isCurrent
                                                ? Colors.white
                                                : Colors.grey.shade400,
                                          ),
                                        ),
                                        if (!isLast)
                                          Expanded(
                                            child: Container(
                                              width: 2.5,
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                gradient: stage.isCompleted
                                                    ? const LinearGradient(
                                                        colors: [
                                                            Color(0xFFD4AF37),
                                                            Color(0xFFA07212)
                                                          ])
                                                    : null,
                                                color: stage.isCompleted
                                                    ? null
                                                    : Colors.grey.shade200,
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                            bottom: 20.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    stage.title,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                      color: stage.isCurrent ||
                                                              stage.isCompleted
                                                          ? const Color(
                                                              0xFF2A1508)
                                                          : Colors.grey.shade400,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: stage.isCompleted
                                                        ? AppColors.success
                                                            .withOpacity(0.1)
                                                        : Colors.grey.shade100,
                                                    borderRadius:
                                                        BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    stage.time,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: stage.isCompleted
                                                          ? AppColors.success
                                                          : Colors
                                                              .grey.shade500,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              stage.description,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Get.snackbar(
                                    'Calling Spice Haven',
                                    'Connecting to Flagship Outlet (+1 800-SPICE)...',
                                    snackPosition: SnackPosition.TOP,
                                    backgroundColor: const Color(0xFF2A1508),
                                    colorText: Colors.white,
                                    icon: const Icon(Icons.storefront_rounded,
                                        color: AppColors.primary),
                                    margin: const EdgeInsets.all(16),
                                    borderRadius: 14,
                                  );
                                },
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: AppColors.primary, width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.call_outlined,
                                          color: AppColors.primary, size: 18),
                                      SizedBox(width: 6),
                                      Text(
                                        'Call Outlet',
                                        style: TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => Get.offAllNamed(AppRoutes.home),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [
                                      Color(0xFFD4AF37),
                                      Color(0xFFA07212)
                                    ]),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withOpacity(0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.restaurant_rounded,
                                          color: Colors.white, size: 18),
                                      SizedBox(width: 6),
                                      Text(
                                        'Back to Home',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  ),
                  // Smooth overlay when switching orders
                  if (controller.isSwitchingOrder.value)
                    Container(
                      color: Colors.white.withOpacity(0.7),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  // Order Switcher Bottom Sheet
  void _showOrderSwitcherSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Order to Track',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2A1508),
                  ),
                ),
                Obx(() => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${controller.activeOrders.length} Live',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    )),
              ],
            ),
            const SizedBox(height: 14),
            Flexible(
              child: Obx(() {
                final all = controller.recentOrders;
                if (all.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'No orders found for this account.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: all.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, idx) {
                    final ord = all[idx];
                    final isCurrent = ord.id == controller.orderId.value;
                    final isLive = controller.activeOrders.any((a) => a.id == ord.id);
                    final shortId = (ord.id != null && ord.id!.length > 8)
                        ? ord.id!.substring(0, 8)
                        : (ord.id ?? 'Order');

                    Color statusColor = AppColors.success;
                    final s = ord.orderStatus.toLowerCase();
                    if (s.contains('delivery') || s.contains('route')) {
                      statusColor = const Color(0xFF8B5CF6);
                    } else if (s.contains('served')) {
                      statusColor = AppColors.success;
                    } else if (s.contains('ready')) {
                      statusColor = const Color(0xFF10B981);
                    } else if (s.contains('prep') || s.contains('kitchen')) {
                      statusColor = const Color(0xFFFF9800);
                    } else if (s.contains('cancel')) {
                      statusColor = AppColors.error;
                    } else if (s.contains('placed') || s.contains('new')) {
                      statusColor = const Color(0xFF2563EB);
                    }

                    return InkWell(
                      onTap: () {
                        controller.selectOrder(ord.id!);
                        Get.back();
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? const Color(0xFFFFF7ED)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isCurrent
                                ? AppColors.primary
                                : const Color(0xFFE2E8F0),
                            width: isCurrent ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isLive
                                    ? AppColors.primary.withOpacity(0.1)
                                    : Colors.grey.shade200,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isLive
                                    ? Icons.radar_rounded
                                    : Icons.receipt_rounded,
                                color: isLive
                                    ? AppColors.primary
                                    : Colors.grey.shade600,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '#$shortId',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Color(0xFF2A1508),
                                        ),
                                      ),
                                      if (isLive) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF00C853)
                                                .withOpacity(0.12),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'LIVE',
                                            style: TextStyle(
                                              color: Color(0xFF00C853),
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${ord.orderTypeDisplay} • ${AppFormatters.formatCurrency(ord.grandTotal)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Placed: ${AppFormatters.formatOrderDateTime(ord.createdAt)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  Text(
                                    '${ord.orderType == OrderType.delivery ? "Est. Delivery:" : "Est. Ready:"} ${AppFormatters.formatOrderDateTime(ord.effectiveEstimatedDeliveryTime)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isLive
                                          ? AppColors.primary
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    ord.orderStatus.toUpperCase(),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (isCurrent) ...[
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Tracking Now',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}
