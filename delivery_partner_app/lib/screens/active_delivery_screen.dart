import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../models/delivery_assignment.dart';
import '../providers/auth_provider.dart';
import '../providers/duty_provider.dart';
import '../providers/delivery_provider.dart';
import '../services/location_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/pulse_indicator.dart';
import '../widgets/slide_to_action.dart';
import 'customer_info_screen.dart';
import 'delivery_confirmation_screen.dart';
import 'delivery_workflow_screen.dart';
import 'live_navigation_screen.dart';

class ActiveDeliveryScreen extends StatefulWidget {
  const ActiveDeliveryScreen({super.key});

  @override
  State<ActiveDeliveryScreen> createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends State<ActiveDeliveryScreen> {
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _notesController =
      TextEditingController(text: 'Handed over directly to customer');
  bool _isProcessingAction = false;

  @override
  void dispose() {
    _otpController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _makePhoneCall(String phone) async {
    if (phone.isEmpty) return;
    final cleanPhone = phone.replaceAll(' ', '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not dial $cleanPhone')),
        );
      }
    }
  }

  Future<void> _openNavigation(String destination) async {
    final query = Uri.encodeComponent(destination);
    final googleMapsUri =
        Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$query');
    try {
      if (await canLaunchUrl(googleMapsUri)) {
        await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open map for $destination')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final deliveryProv = Provider.of<DeliveryProvider>(context);
    final authProv = Provider.of<AuthProvider>(context);
    final dutyProv = Provider.of<DutyProvider>(context);
    final assignment = deliveryProv.activeAssignment;
    final orderDetail = deliveryProv.currentOrderDetail;
    final partnerId = authProv.partner?.partnerId ?? '';

    if (assignment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Active Delivery')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline_rounded,
                  size: 64, color: AppTheme.emerald),
              const SizedBox(height: 16),
              const Text('No active delivery at the moment',
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back to Dashboard'),
              ),
            ],
          ),
        ),
      );
    }

    final isPhaseB = assignment.isPickedUp || dutyProv.isOnDelivery;

    return Scaffold(
      appBar: AppBar(
        elevation: 3,
        shadowColor: Colors.black26,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.luxuryHeaderGradient,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isPhaseB
                  ? 'Phase B: En-Route to Customer'
                  : 'Phase A: Heading to Kitchen',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.lightOnDarkTitle),
            ),
            Text(
              'Order #ORD-${assignment.orderId.length > 6 ? assignment.orderId.substring(0, 6).toUpperCase() : "1092"}',
              style:
                  const TextStyle(fontSize: 12, color: AppTheme.lightOnDarkSub),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isPhaseB
                  ? AppTheme.statusSuccess.withOpacity(0.2)
                  : AppTheme.gold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color:
                      isPhaseB ? AppTheme.statusSuccess : AppTheme.goldLight),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PulseIndicator(
                    isActive: true,
                    activeColor:
                        isPhaseB ? AppTheme.statusSuccess : AppTheme.goldLight,
                    size: 8),
                const SizedBox(width: 6),
                Text(
                  isPhaseB ? 'ON DELIVERY' : 'PICKUP PENDING',
                  style: TextStyle(
                    color:
                        isPhaseB ? AppTheme.statusSuccess : AppTheme.goldLight,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Stepper Progress Header
              _buildStepperHeader(isPhaseB),
              const SizedBox(height: 14),

              // Visily Quick Tools Bar
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderSlate),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LiveNavigationScreen()),
                        );
                      },
                      child: const Row(
                        children: [
                          Icon(Icons.navigation_rounded,
                              size: 16, color: AppTheme.primaryGold),
                          SizedBox(width: 4),
                          Text('Live Map',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.titleHeading)),
                        ],
                      ),
                    ),
                    Container(
                        width: 1, height: 18, color: AppTheme.borderSlate),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const DeliveryWorkflowScreen()),
                        );
                      },
                      child: const Row(
                        children: [
                          Icon(Icons.checklist_rounded,
                              size: 16, color: AppTheme.primaryDark),
                          SizedBox(width: 4),
                          Text('Workflow',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.titleHeading)),
                        ],
                      ),
                    ),
                    Container(
                        width: 1, height: 18, color: AppTheme.borderSlate),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CustomerInfoScreen(
                              customerName: assignment.customerName,
                              phone: assignment.customerPhone,
                              address: assignment.deliveryAddress,
                            ),
                          ),
                        );
                      },
                      child: const Row(
                        children: [
                          Icon(Icons.person_pin_circle_rounded,
                              size: 16, color: AppTheme.statusSuccess),
                          SizedBox(width: 4),
                          Text('Customer',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.titleHeading)),
                        ],
                      ),
                    ),
                    Container(
                        width: 1, height: 18, color: AppTheme.borderSlate),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const DeliveryConfirmationScreen()),
                        );
                      },
                      child: const Row(
                        children: [
                          Icon(Icons.verified_rounded,
                              size: 16, color: Color(0xFF6366F1)),
                          SizedBox(width: 4),
                          Text('Proof',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.titleHeading)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Phase A or Phase B Content
              if (!isPhaseB) ...[
                _buildPhaseAPickup(context, assignment, orderDetail,
                    deliveryProv, partnerId, dutyProv),
              ] else ...[
                _buildPhaseBDelivery(
                    context, assignment, deliveryProv, partnerId, dutyProv),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepperHeader(bool isPhaseB) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Step 1
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isPhaseB ? AppTheme.emerald : AppTheme.amber,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      isPhaseB ? Icons.check_rounded : Icons.store_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('1. Kitchen',
                          style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                      Text('Item verification',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Icon(Icons.arrow_forward_rounded,
              color: isPhaseB ? AppTheme.emerald : AppTheme.textMuted,
              size: 18),
          const SizedBox(width: 8),

          // Step 2
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color:
                        isPhaseB ? AppTheme.emerald : AppTheme.surfaceHighlight,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: isPhaseB
                            ? AppTheme.emeraldNeon
                            : AppTheme.borderSlate),
                  ),
                  child: const Center(
                    child:
                        Icon(Icons.home_rounded, color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('2. Drop-off',
                          style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                      Text('Customer OTP',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseAPickup(
    BuildContext context,
    DeliveryAssignment assignment,
    dynamic orderDetail,
    DeliveryProvider deliveryProv,
    String partnerId,
    DutyProvider dutyProv,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Kitchen Information Card
        GlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.restaurant_rounded,
                        size: 28, color: AppTheme.amber),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gourmet Bistro - Main Kitchen',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Central Kitchen & Dispatch Point',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceHighlight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'ORDER #${assignment.orderId.length > 6 ? assignment.orderId.substring(0, 6).toUpperCase() : assignment.orderId}',
                            style: const TextStyle(
                              color: AppTheme.emeraldNeon,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppTheme.borderSlate),
              const SizedBox(height: 12),

              // Quick Actions: Call Restaurant & Directions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _makePhoneCall('+919876543210'),
                      icon: const Icon(Icons.phone_rounded,
                          size: 16, color: AppTheme.emerald),
                      label: const Text('Call Kitchen',
                          style: TextStyle(
                              color: AppTheme.textPrimary, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.borderSlate),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _openNavigation('Gourmet Bistro Main Kitchen'),
                      icon: const Icon(Icons.directions_rounded,
                          size: 16, color: AppTheme.amber),
                      label: const Text('Directions',
                          style: TextStyle(
                              color: AppTheme.textPrimary, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.borderSlate),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Kitchen Order Checklist
        GlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Order Checklist for Kitchen',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    '${orderDetail?.items.length ?? 0} items',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Verify all packages before departing from the kitchen.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 14),
              if (orderDetail != null && orderDetail.items.isNotEmpty)
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: orderDetail.items.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: AppTheme.borderSlate, height: 16),
                  itemBuilder: (context, index) {
                    final item = orderDetail.items[index];
                    return InkWell(
                      onTap: () => deliveryProv.toggleItemCheck(index),
                      child: Row(
                        children: [
                          Checkbox(
                            value: item.isChecked,
                            activeColor: AppTheme.emerald,
                            checkColor: Colors.white,
                            onChanged: (val) =>
                                deliveryProv.toggleItemCheck(index),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: TextStyle(
                                    color: item.isChecked
                                        ? AppTheme.textSecondary
                                        : AppTheme.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    decoration: item.isChecked
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                if (item.specialInstructions != null &&
                                    item.specialInstructions!.isNotEmpty)
                                  Text(
                                    'Note: ${item.specialInstructions}',
                                    style: const TextStyle(
                                        color: AppTheme.amber, fontSize: 12),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceHighlight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'x${item.quantity}',
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Loading items from kitchen POS...',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Slide to Confirm Pickup CTA
        SlideToAction(
          text: 'SLIDE TO CONFIRM PICKUP',
          actionColor: AppTheme.amber,
          icon: Icons.store_mall_directory_rounded,
          isLoading: _isProcessingAction,
          onSlideComplete: () async {
            setState(() => _isProcessingAction = true);
            final ok = await deliveryProv.pickupOrder(
                assignment.assignmentId, partnerId);
            setState(() => _isProcessingAction = false);
            if (ok) {
              dutyProv.forceLocalStatus('ON_DELIVERY');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order picked up! Now en-route to customer.'),
                    backgroundColor: AppTheme.emerald,
                  ),
                );
              }
            } else if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      deliveryProv.errorMessage ?? 'Failed to confirm pickup'),
                  backgroundColor: AppTheme.rose,
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildPhaseBDelivery(
    BuildContext context,
    DeliveryAssignment assignment,
    DeliveryProvider deliveryProv,
    String partnerId,
    DutyProvider dutyProv,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Live Route Preview Map Widget
        Container(
          height: 190,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderSlate, width: 1.5),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x0C000000),
                  blurRadius: 16,
                  offset: Offset(0, 4)),
            ],
          ),
          child: Stack(
            children: [
              // Stylized grid background lines
              Positioned.fill(
                child: CustomPaint(
                  painter: _RouteMapPainter(),
                ),
              ),

              // Live Status Badge on Map
              Positioned(
                top: 14,
                left: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.orange.withOpacity(0.5)),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 8,
                          offset: Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PulseIndicator(
                          isActive: true,
                          size: 8,
                          activeColor: AppTheme.orange),
                      const SizedBox(width: 6),
                      ValueListenableBuilder<Map<String, dynamic>>(
                        valueListenable: LocationService.locationNotifier,
                        builder: (context, val, child) {
                          return Text(
                            'GPS LIVE: ${(val['latitude'] as double).toStringAsFixed(4)}, ${(val['longitude'] as double).toStringAsFixed(4)}',
                            style: const TextStyle(
                              color: AppTheme.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // ETA and Distance floating banner
              Positioned(
                bottom: 12,
                left: 14,
                right: 14,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xE60F172A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderSlate),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.near_me_rounded,
                              color: AppTheme.emeraldNeon, size: 18),
                          SizedBox(width: 8),
                          Text('ETA: ~12 Mins',
                              style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                        ],
                      ),
                      Text('Distance: 2.8 km',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Customer Drop-off Details Card
        GlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.emerald.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.location_on_rounded,
                        size: 28, color: AppTheme.emeraldNeon),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Customer Drop-off Location',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          assignment.deliveryAddress,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Phone: ${assignment.customerPhone}',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Customer Delivery Notes Banner
              if (assignment.deliveryNotes != null &&
                  assignment.deliveryNotes!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.amber.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.amber.withOpacity(0.35)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppTheme.amber, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Delivery Note: "${assignment.deliveryNotes}"',
                          style: const TextStyle(
                            color: AppTheme.amber,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),
              const Divider(color: AppTheme.borderSlate),
              const SizedBox(height: 12),

              // Quick Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _makePhoneCall(assignment.customerPhone),
                      icon: const Icon(Icons.phone_rounded, size: 18),
                      label: const Text('Call Customer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emerald,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _openNavigation(assignment.deliveryAddress),
                      icon: const Icon(Icons.navigation_rounded,
                          size: 18, color: AppTheme.emeraldNeon),
                      label: const Text('Open Map',
                          style: TextStyle(color: AppTheme.textPrimary)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.borderSlate),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Drop-off OTP Verification Sheet
        GlassCard(
          padding: const EdgeInsets.all(20),
          borderColor: AppTheme.emerald.withOpacity(0.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Drop-off OTP Verification',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Ask the customer for the 4-digit verification code received on their phone.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),

              // OTP Input
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                style: const TextStyle(
                  color: AppTheme.emeraldNeon,
                  fontSize: 24,
                  letterSpacing: 12,
                  fontWeight: FontWeight.w900,
                ),
                decoration: InputDecoration(
                  hintText: '••••',
                  counterText: '',
                  prefixIcon:
                      const Icon(Icons.pin_rounded, color: AppTheme.emerald),
                  suffixIcon: assignment.otpCode != null
                      ? TextButton(
                          onPressed: () =>
                              _otpController.text = assignment.otpCode!,
                          child: const Text('Fill OTP',
                              style: TextStyle(color: AppTheme.emeraldNeon)),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 14),

              // Delivery Notes Input
              TextField(
                controller: _notesController,
                style:
                    const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Delivery Remarks / Handover Notes',
                  hintText: 'e.g. Handed over directly to customer',
                  prefixIcon: Icon(Icons.note_alt_outlined,
                      color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Slide to Complete Delivery CTA
        SlideToAction(
          text: 'SLIDE TO COMPLETE DELIVERY',
          actionColor: AppTheme.emerald,
          icon: Icons.verified_rounded,
          isLoading: _isProcessingAction,
          onSlideComplete: () async {
            final otp = _otpController.text.trim();
            if (otp.length != 4) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter the 4-digit drop-off OTP'),
                  backgroundColor: AppTheme.rose,
                ),
              );
              return;
            }

            setState(() => _isProcessingAction = true);
            final ok = await deliveryProv.completeDelivery(
              assignment.assignmentId,
              partnerId,
              otp,
              _notesController.text.trim(),
            );
            setState(() => _isProcessingAction = false);

            if (ok) {
              dutyProv.forceLocalStatus('ONLINE');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Delivery completed successfully! Earned ₹${(assignment.deliveryFee + assignment.tipAmount).toStringAsFixed(0)}'),
                    backgroundColor: AppTheme.emerald,
                  ),
                );
                Navigator.of(context).pop();
              }
            } else if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      deliveryProv.errorMessage ?? 'Invalid delivery OTP code'),
                  backgroundColor: AppTheme.rose,
                ),
              );
            }
          },
        ),
      ],
    );
  }
}

// Custom Painter for route map aesthetic with orange route line
class _RouteMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0x2094A3B8)
      ..strokeWidth = 1.0;

    // Grid lines
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Curving road line
    final routePaint = Paint()
      ..color = AppTheme.orange
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(35, size.height - 40);
    path.quadraticBezierTo(size.width * 0.45, size.height * 0.7,
        size.width * 0.5, size.height * 0.45);
    path.quadraticBezierTo(
        size.width * 0.6, size.height * 0.2, size.width - 45, 45);

    canvas.drawPath(path, routePaint);

    // Origin (Kitchen Pin)
    final originPaint = Paint()..color = AppTheme.amber;
    canvas.drawCircle(Offset(35, size.height - 40), 7, originPaint);

    // Destination (Customer Pin)
    final destPaint = Paint()..color = AppTheme.orangeNeon;
    canvas.drawCircle(Offset(size.width - 45, 45), 8, destPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
