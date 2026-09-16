import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/delivery_assignment.dart';
import '../providers/auth_provider.dart';
import '../providers/delivery_provider.dart';
import '../providers/duty_provider.dart';
import 'active_delivery_screen.dart';
import 'order_details_screen.dart';

class AssignedOrdersScreen extends StatefulWidget {
  final bool showAppBar;
  const AssignedOrdersScreen({super.key, this.showAppBar = true});

  @override
  State<AssignedOrdersScreen> createState() => _AssignedOrdersScreenState();
}

class _AssignedOrdersScreenState extends State<AssignedOrdersScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['All Active', 'Pending Acceptance', 'En-Route'];

  @override
  Widget build(BuildContext context) {
    final deliveryProv = Provider.of<DeliveryProvider>(context);
    final authProv = Provider.of<AuthProvider>(context);
    final dutyProv = Provider.of<DutyProvider>(context);
    final partner = authProv.partner;

    // Filter assignments strictly from real backend deliveries
    final allActive = deliveryProv.deliveries.where((d) => d.isActive).toList();
    final displayedOrders = allActive.where((item) {
      if (_selectedFilterIndex == 1) return item.isAssigned;
      if (_selectedFilterIndex == 2) return item.isPickedUp || item.isAccepted;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: widget.showAppBar
          ? AppBar(
              titleSpacing: 16,
              elevation: 3,
              shadowColor: Colors.black26,
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.luxuryHeaderGradient,
                ),
              ),
              title: const Text(
                'Assigned Orders',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.lightOnDarkTitle,
                ),
              ),
              actions: [
                IconButton(
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh_rounded, color: AppTheme.goldLight),
                  onPressed: () {
                    if (partner != null) {
                      deliveryProv.fetchDeliveries(partner.partnerId);
                    }
                  },
                ),
                const SizedBox(width: 8),
              ],
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            // Filter Pills Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_filters.length, (index) {
                    final isSelected = _selectedFilterIndex == index;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          _filters[index],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : AppTheme.textSecondary,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryGold,
                        backgroundColor: AppTheme.surfaceSlate,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? AppTheme.primaryGold : Colors.transparent,
                          ),
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _selectedFilterIndex = index);
                        },
                      ),
                    );
                  }),
                ),
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderSlate),

            // Orders list
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  if (partner != null) {
                    await deliveryProv.fetchDeliveries(partner.partnerId);
                  }
                },
                child: displayedOrders.isNotEmpty
                    ? ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: displayedOrders.length,
                        itemBuilder: (context, index) {
                          final assignment = displayedOrders[index];
                          return _buildOrderCard(context, assignment, deliveryProv, partner?.partnerId ?? '', dutyProv);
                        },
                      )
                    : _buildEmptyState(context, deliveryProv, partner?.partnerId ?? ''),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, DeliveryProvider deliveryProv, String partnerId) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.two_wheeler_rounded,
                size: 46,
                color: AppTheme.primaryGold,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Assigned Orders Waiting',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.titleHeading,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You are online and ready for orders. As soon as a customer order is placed, it will be automatically routed here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.bodySecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryDark,
                foregroundColor: AppTheme.primaryGold,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Check for Orders', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                if (partnerId.isNotEmpty) {
                  deliveryProv.fetchDeliveries(partnerId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Checking server for newly dispatched orders...')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(
    BuildContext context,
    DeliveryAssignment assignment,
    DeliveryProvider deliveryProv,
    String partnerId,
    DutyProvider dutyProv,
  ) {
    final isNewAssignment = assignment.isAssigned;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNewAssignment ? AppTheme.goldLight : AppTheme.borderSlate,
          width: isNewAssignment ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isNewAssignment ? const Color(0xFFFFFBEB) : AppTheme.primaryLight.withOpacity(0.4),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildSourceTag('SPICE HAVEN'),
                    const SizedBox(width: 8),
                    Text(
                      assignment.orderNumber,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isNewAssignment ? Colors.amber.shade50 : AppTheme.emerald.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isNewAssignment ? Colors.amber.shade300 : AppTheme.emerald.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isNewAssignment ? Icons.schedule_rounded : Icons.check_circle_outline_rounded,
                        size: 13,
                        color: isNewAssignment ? Colors.amber.shade900 : AppTheme.emerald,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        assignment.status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isNewAssignment ? Colors.amber.shade900 : AppTheme.emerald,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assignment.customerName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.titleHeading),
                ),
                const SizedBox(height: 10),

                // Route Details
                _buildRouteTimeline(assignment.restaurantName, assignment.deliveryAddress),
                const SizedBox(height: 12),

                // Item summary if available
                if (assignment.itemSummary != null && assignment.itemSummary!.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceSlate,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      assignment.itemSummary!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Payout & Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Trip Earnings', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                        Text(
                          '₹${assignment.totalEarning.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.primaryDark),
                        ),
                      ],
                    ),

                    if (isNewAssignment)
                      Row(
                        children: [
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.rose,
                              side: const BorderSide(color: AppTheme.rose),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            onPressed: () async {
                              final ok = await deliveryProv.rejectAssignment(assignment.assignmentId, partnerId);
                              if (ok && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Assignment declined')),
                                );
                              }
                            },
                            child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGold,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            ),
                            onPressed: () async {
                              final ok = await deliveryProv.acceptAssignment(assignment.assignmentId, partnerId);
                              if (ok && context.mounted) {
                                dutyProv.forceLocalStatus('ON_DELIVERY');
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ActiveDeliveryScreen()),
                                );
                              }
                            },
                            child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      )
                    else
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryDark,
                          foregroundColor: AppTheme.primaryGold,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrderDetailsScreen(assignment: assignment),
                            ),
                          );
                        },
                        child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteTimeline(String restaurant, String customerAddress) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryGold,
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 2,
                  height: 22,
                  color: AppTheme.borderSlate,
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pickup', style: TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
                  Text(
                    restaurant,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppTheme.statusSuccess,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Drop-off', style: TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
                  Text(
                    customerAddress,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSourceTag(String source) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        source.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryDark,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
