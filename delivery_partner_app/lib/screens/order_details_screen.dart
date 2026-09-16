import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../models/delivery_assignment.dart';
import '../providers/auth_provider.dart';
import '../providers/delivery_provider.dart';
import 'customer_info_screen.dart';
import 'delivery_workflow_screen.dart';
import 'live_navigation_screen.dart';

class OrderDetailsScreen extends StatefulWidget {
  final DeliveryAssignment? assignment;

  const OrderDetailsScreen({super.key, this.assignment});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  bool _isAccepting = false;
  bool _isLoadingDetails = false;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final orderId = widget.assignment?.orderId;
    if (orderId != null && orderId.isNotEmpty) {
      setState(() => _isLoadingDetails = true);
      try {
        await Provider.of<DeliveryProvider>(context, listen: false).loadOrderDetail(orderId);
      } catch (_) {}
      if (mounted) {
        setState(() => _isLoadingDetails = false);
      }
    }
  }

  Future<void> _makeCall(String phone) async {
    if (phone.isEmpty) return;
    final clean = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final deliveryProv = Provider.of<DeliveryProvider>(context);

    final assignment = widget.assignment;
    if (assignment == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Order Details'),
          backgroundColor: AppTheme.darkSurface,
        ),
        body: const Center(
          child: Text('No order assignment specified.', style: TextStyle(color: AppTheme.textMuted)),
        ),
      );
    }

    final orderNumber = assignment.orderNumber.isNotEmpty
        ? assignment.orderNumber
        : '#${assignment.orderId.substring(0, assignment.orderId.length > 8 ? 8 : assignment.orderId.length).toUpperCase()}';

    final customerName = assignment.customerName;
    final customerPhone = assignment.customerPhone;
    final dropAddress = assignment.deliveryAddress;
    final restaurantName = assignment.restaurantName;
    final totalRiderEarning = assignment.totalEarning > 0 ? assignment.totalEarning : (assignment.deliveryFee + assignment.tipAmount);

    final orderDetail = deliveryProv.currentOrderDetail;
    final hasItems = orderDetail != null && orderDetail.items.isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        elevation: 3,
        shadowColor: Colors.black26,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.luxuryHeaderGradient,
          ),
        ),
        title: Text(
          'Order Details $orderNumber',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.lightOnDarkTitle),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _buildStatusBadge(assignment.status),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDetails,
        color: AppTheme.primaryGold,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Customer Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderSlate),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 26,
                      backgroundColor: AppTheme.primaryLight,
                      child: Icon(Icons.person_rounded, color: AppTheme.primaryGold, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customerName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.titleHeading),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            customerPhone.isNotEmpty ? customerPhone : 'No contact provided',
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    if (customerPhone.isNotEmpty) ...[
                      InkWell(
                        onTap: () => _makeCall(customerPhone),
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: AppTheme.surfaceSlate,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.phone_rounded, color: AppTheme.primaryGold, size: 20),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CustomerInfoScreen(
                              customerName: customerName,
                              phone: customerPhone,
                              address: dropAddress,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: AppTheme.surfaceSlate,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.info_outline_rounded, color: AppTheme.titleHeading, size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Route & Timeline Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderSlate),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DELIVERY ROUTE',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textMuted, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 14),
                    _buildDetailedTimeline(restaurantName, dropAddress),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Customer Special Instructions
              if (orderDetail?.deliveryNotes != null && orderDetail!.deliveryNotes!.trim().isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.speaker_notes_outlined, color: Color(0xFFD97706), size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Customer Delivery Note',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF92400E)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              orderDetail.deliveryNotes!,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF78350F), height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Items Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderSlate),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ORDER ITEMS',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textMuted, letterSpacing: 0.5),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceSlate,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            hasItems
                                ? '${orderDetail.items.length} Items'
                                : (assignment.itemsCount > 0 ? '${assignment.itemsCount} Items' : '1 Item'),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isLoadingDetails) ...[
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGold),
                        ),
                      ),
                    ] else if (hasItems) ...[
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: orderDetail.items.length,
                        separatorBuilder: (_, __) => const Divider(height: 16, color: AppTheme.borderSubtle),
                        itemBuilder: (context, index) {
                          final item = orderDetail.items[index];
                          return _buildItemRow(
                            '${item.quantity}x',
                            item.name,
                            item.totalPrice > 0 ? '₹${item.totalPrice.toStringAsFixed(2)}' : '',
                          );
                        },
                      ),
                    ] else if (assignment.itemSummary?.isNotEmpty == true) ...[
                      _buildItemRow('•', assignment.itemSummary!, assignment.totalOrderAmount > 0 ? '₹${assignment.totalOrderAmount.toStringAsFixed(2)}' : ''),
                    ] else ...[
                      const Text(
                        'Item details confirmed at dispatch counter.',
                        style: TextStyle(fontSize: 13, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Payout Breakdown
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderSlate),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PAYOUT DETAILS',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textMuted, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 12),
                    _buildPayoutLine('Base Delivery Fee', '₹${(assignment.deliveryFee * 0.8).toStringAsFixed(2)}'),
                    const SizedBox(height: 6),
                    _buildPayoutLine('Distance & Surge Pay', '₹${(assignment.deliveryFee * 0.2).toStringAsFixed(2)}'),
                    if (assignment.tipAmount > 0) ...[
                      const SizedBox(height: 6),
                      _buildPayoutLine('Customer Tip', '₹${assignment.tipAmount.toStringAsFixed(2)}', isGreen: true),
                    ],
                    const Divider(height: 20, color: AppTheme.borderSlate),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Rider Earning',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.titleHeading),
                        ),
                        Text(
                          '₹${totalRiderEarning.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.primaryGold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action CTA: Accept if pending or unassigned
              if (assignment.status == 'ASSIGNED' || assignment.status == 'PENDING') ...[
                Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.imperialActionGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGold.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isAccepting
                        ? null
                        : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(context);
                            setState(() => _isAccepting = true);
                            bool ok = false;
                            if (authProv.partner != null) {
                              ok = await deliveryProv.acceptAssignment(assignment.assignmentId, authProv.partner!.partnerId);
                            }
                            if (!mounted) return;
                            setState(() => _isAccepting = false);

                            if (ok) {
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Order Accepted! Proceeding to pickup...')),
                              );
                              navigator.pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => const DeliveryWorkflowScreen(),
                                ),
                              );
                            } else {
                              messenger.showSnackBar(
                                SnackBar(content: Text(deliveryProv.errorMessage ?? 'Failed to accept order')),
                              );
                            }
                          },
                    child: _isAccepting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 20),
                              SizedBox(width: 8),
                              Text('Accept Assignment & Navigate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 12),
              ] else ...[
                Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.imperialActionGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DeliveryWorkflowScreen(),
                        ),
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions_bike_rounded, size: 20),
                        SizedBox(width: 8),
                        Text('Open Active Delivery Workflow', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryDark,
                  side: const BorderSide(color: AppTheme.primaryGold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LiveNavigationScreen(),
                    ),
                  );
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Preview Live Route Map', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedTimeline(String restaurant, String customer) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.storefront_rounded, size: 16, color: AppTheme.primaryGold),
                ),
                Container(
                  width: 2,
                  height: 36,
                  color: AppTheme.borderSlate,
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PICKUP POINT', style: TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(restaurant, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.titleHeading)),
                  const Text('Kitchen dispatch counter', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.statusSuccess.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_on_rounded, size: 16, color: AppTheme.statusSuccess),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CUSTOMER DROP-OFF', style: TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(customer, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.titleHeading)),
                  const Text('Destination drop address', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildItemRow(String qty, String title, String price) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(qty, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryDark)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
        ),
        if (price.isNotEmpty)
          Text(price, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.titleHeading)),
      ],
    );
  }

  Widget _buildPayoutLine(String label, String amount, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        Text(
          amount,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isGreen ? AppTheme.statusSuccess : AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = AppTheme.primaryLight;
    Color fg = AppTheme.primaryDark;

    if (status == 'ACCEPTED' || status == 'IN_TRANSIT' || status == 'PICKED_UP') {
      bg = const Color(0xFFEFF6FF);
      fg = const Color(0xFF2563EB);
    } else if (status == 'DELIVERED') {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF15803D);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withOpacity(0.3)),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
