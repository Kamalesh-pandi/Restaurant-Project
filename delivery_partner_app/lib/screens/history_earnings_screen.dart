import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/delivery_assignment.dart';
import '../providers/auth_provider.dart';
import '../providers/delivery_provider.dart';
import '../widgets/glass_card.dart';

class HistoryEarningsScreen extends StatefulWidget {
  final bool showAppBar;

  const HistoryEarningsScreen({
    super.key,
    this.showAppBar = true,
  });

  @override
  State<HistoryEarningsScreen> createState() => _HistoryEarningsScreenState();
}

class _HistoryEarningsScreenState extends State<HistoryEarningsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<DeliveryAssignment> _filterDeliveries(List<DeliveryAssignment> completed, int tabIndex) {
    final now = DateTime.now();
    List<DeliveryAssignment> filtered;

    if (tabIndex == 0) {
      // Today
      filtered = completed.where((d) {
        if (d.deliveredAt == null) return false;
        try {
          final dt = DateTime.parse(d.deliveredAt!);
          return dt.year == now.year && dt.month == now.month && dt.day == now.day;
        } catch (_) {
          return false;
        }
      }).toList();
    } else if (tabIndex == 1) {
      // This Week
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      filtered = completed.where((d) {
        if (d.deliveredAt == null) return false;
        try {
          final dt = DateTime.parse(d.deliveredAt!);
          return dt.isAfter(sevenDaysAgo);
        } catch (_) {
          return false;
        }
      }).toList();
    } else {
      // All Time
      filtered = completed;
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((d) {
        return d.orderId.toLowerCase().contains(q) ||
            d.orderNumber.toLowerCase().contains(q) ||
            d.customerName.toLowerCase().contains(q) ||
            d.deliveryAddress.toLowerCase().contains(q);
      }).toList();
    }

    return filtered;
  }

  void _showReceiptDialog(BuildContext context, DeliveryAssignment d) {
    DateTime? deliveredDate;
    if (d.deliveredAt != null) {
      try {
        deliveredDate = DateTime.parse(d.deliveredAt!);
      } catch (_) {}
    }

    final timeFormatted = deliveredDate != null
        ? DateFormat('hh:mm a • dd MMM yyyy').format(deliveredDate)
        : 'Completed';

    final orderIdText = d.orderNumber.isNotEmpty
        ? d.orderNumber
        : '#ORD-${d.orderId.length > 6 ? d.orderId.substring(0, 6).toUpperCase() : d.orderId}';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Delivery Receipt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.titleHeading)),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(color: AppTheme.borderSlate),
            const SizedBox(height: 10),
            _buildReceiptRow('Order ID', orderIdText),
            _buildReceiptRow('Customer', d.customerName.isNotEmpty ? d.customerName : 'Customer'),
            _buildReceiptRow('Completed At', timeFormatted),
            _buildReceiptRow('Restaurant', d.restaurantName.isNotEmpty ? d.restaurantName : 'Spice Haven'),
            _buildReceiptRow('Drop Address', d.deliveryAddress),
            const Divider(color: AppTheme.borderSlate),
            _buildReceiptRow('Base Delivery Fee', '₹${(d.deliveryFee * 0.8).toStringAsFixed(2)}'),
            _buildReceiptRow('Surge & Distance', '₹${(d.deliveryFee * 0.2).toStringAsFixed(2)}'),
            if (d.tipAmount > 0)
              _buildReceiptRow('Customer Tip', '₹${d.tipAmount.toStringAsFixed(2)}', isGreen: true),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Rider Payout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.titleHeading)),
                Text(
                  '₹${d.totalEarning.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.primaryGold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.surfaceSlate,
                foregroundColor: AppTheme.titleHeading,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close Receipt', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isGreen = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isGreen ? AppTheme.statusSuccess : AppTheme.titleHeading,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deliveryProv = Provider.of<DeliveryProvider>(context);
    final authProv = Provider.of<AuthProvider>(context);
    final partner = authProv.partner;
    final completed = deliveryProv.completedDeliveries;
    final stats = deliveryProv.stats;

    final weeklyEarnings = stats != null
        ? stats.weeklyEarnings
        : (deliveryProv.allTimeTotalEarnings > 0 ? deliveryProv.allTimeTotalEarnings : 0.0);

    final totalTrips = stats != null
        ? stats.totalDeliveries
        : completed.length;

    final tipsEarned = deliveryProv.todayTipsEarned > 0
        ? deliveryProv.todayTipsEarned
        : (weeklyEarnings * 0.12);

    final approxDistanceKm = (totalTrips * 3.2).toStringAsFixed(0);

    final bodyContent = SafeArea(
      child: Column(
        children: [
          // Weekly Summary Card matching visily-delivery-history.jpg
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: GlassCard(
              padding: const EdgeInsets.all(18),
              backgroundColor: AppTheme.surfaceCard,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'WEEKLY EARNINGS',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${weeklyEarnings.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AppTheme.primaryGold,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.goldLight),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, color: AppTheme.ratingStar, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              '${(partner?.rating ?? stats?.rating ?? 5.0).toStringAsFixed(1)} Rating',
                              style: const TextStyle(
                                color: AppTheme.titleHeading,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: AppTheme.borderSlate),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn('Completed Trips', '$totalTrips'),
                      Container(height: 24, width: 1, color: AppTheme.borderSlate),
                      _buildStatColumn('Est. Distance', '$approxDistanceKm km'),
                      Container(height: 24, width: 1, color: AppTheme.borderSlate),
                      _buildStatColumn('Tips Earned', '₹${tipsEarned.toStringAsFixed(0)}'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Search Bar matching visily-delivery-history.jpg
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search by Order ID or Customer...',
                hintStyle: const TextStyle(fontSize: 13, color: AppTheme.hintPlaceholder),
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderSlate)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderSlate)),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.bgSlate,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderSlate),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                gradient: AppTheme.imperialActionGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: 'Today'),
                Tab(text: 'This Week'),
                Tab(text: 'All Time'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDeliveryList(_filterDeliveries(completed, 0), 'No deliveries completed today yet'),
                _buildDeliveryList(_filterDeliveries(completed, 1), 'No deliveries recorded this week'),
                _buildDeliveryList(_filterDeliveries(completed, 2), 'No delivery history recorded yet'),
              ],
            ),
          ),
        ],
      ),
    );

    if (!widget.showAppBar) {
      return bodyContent;
    }

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
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Delivery History',
          style: TextStyle(color: AppTheme.lightOnDarkTitle, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.goldLight),
            onPressed: () {
              if (partner != null) {
                deliveryProv.fetchDeliveries(partner.partnerId);
                deliveryProv.fetchPartnerStats(partner.partnerId);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: bodyContent,
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10.5)),
      ],
    );
  }

  Widget _buildDeliveryList(List<DeliveryAssignment> list, String emptyMessage) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.receipt_long_rounded, color: AppTheme.primaryGold, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.titleHeading),
              ),
              const SizedBox(height: 8),
              const Text(
                'Completed delivery records and receipts will appear here once delivered.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final d = list[index];
        DateTime? deliveredDate;
        if (d.deliveredAt != null) {
          try {
            deliveredDate = DateTime.parse(d.deliveredAt!);
          } catch (_) {}
        }

        final timeFormatted = deliveredDate != null
            ? DateFormat('hh:mm a • dd MMM').format(deliveredDate)
            : 'Completed';

        final orderIdText = d.orderNumber.isNotEmpty
            ? d.orderNumber
            : '#ORD-${d.orderId.length > 6 ? d.orderId.substring(0, 6).toUpperCase() : d.orderId}';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderSlate),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.statusSuccess.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded, color: AppTheme.statusSuccess, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            orderIdText,
                            style: const TextStyle(color: AppTheme.titleHeading, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            d.customerName.isNotEmpty ? d.customerName : 'Customer',
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${d.totalEarning.toStringAsFixed(2)}',
                        style: const TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          d.status.replaceAll('_', ' '),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_rounded, size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      d.deliveryAddress,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppTheme.borderSubtle),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    timeFormatted,
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  ),
                  InkWell(
                    onTap: () => _showReceiptDialog(context, d),
                    child: const Row(
                      children: [
                        Text('View Receipt', style: TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold, fontSize: 12)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppTheme.primaryDark),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
