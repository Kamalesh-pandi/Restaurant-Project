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
import '../widgets/incoming_order_dialog.dart';
import 'active_delivery_screen.dart';
import 'assigned_orders_screen.dart';
import 'history_earnings_screen.dart';
import 'live_navigation_screen.dart';
import 'login_screen.dart';
import 'order_details_screen.dart';
import 'profile_support_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;
  bool _isModalShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeRiderData();
    });
  }

  void _initializeRiderData() {
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final dutyProv = Provider.of<DutyProvider>(context, listen: false);
    final deliveryProv = Provider.of<DeliveryProvider>(context, listen: false);

    if (authProv.partner != null) {
      dutyProv.initStatus(authProv.partner);
      deliveryProv.startPolling(authProv.partner!.partnerId, isOnline: dutyProv.isOnline || dutyProv.isOnDelivery);
    }
  }

  void _checkIncomingAssignment(DeliveryProvider deliveryProv) {
    if (deliveryProv.incomingAssignment != null && !_isModalShowing) {
      _isModalShowing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => IncomingOrderDialog(assignment: deliveryProv.incomingAssignment!),
        ).then((_) {
          _isModalShowing = false;
        });
      });
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
    final authProv = Provider.of<AuthProvider>(context);
    final dutyProv = Provider.of<DutyProvider>(context);
    final deliveryProv = Provider.of<DeliveryProvider>(context);
    final partner = authProv.partner;

    _checkIncomingAssignment(deliveryProv);

    final isOnline = dutyProv.isOnline || dutyProv.isOnDelivery;

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: _buildAppBar(context, partner, dutyProv, deliveryProv, authProv),
      body: IndexedStack(
        index: _currentNavIndex,
        children: [
          // Tab 0: Dashboard (visily-delivery-dashboard.jpg)
          _buildDashboardTab(context, partner, dutyProv, deliveryProv, isOnline),

          // Tab 1: Assigned Orders (visily-assigned-orders.jpg)
          const AssignedOrdersScreen(showAppBar: false),

          // Tab 2: Live Navigation (visily-live-navigation.jpg)
          const LiveNavigationScreen(showAppBar: false),

          // Tab 3: History (visily-delivery-history.jpg)
          const HistoryEarningsScreen(showAppBar: false),

          // Tab 4: Profile & Support (visily-profile-&-support.jpg)
          const ProfileSupportScreen(showAppBar: false),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.borderSlate, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: _currentNavIndex,
          backgroundColor: Colors.white,
          indicatorColor: AppTheme.primaryLight,
          onDestinationSelected: (index) {
            setState(() => _currentNavIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded, color: AppTheme.primaryGold),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.format_list_bulleted_outlined),
              selectedIcon: Icon(Icons.format_list_bulleted_rounded, color: AppTheme.primaryGold),
              label: 'Assigned',
            ),
            NavigationDestination(
              icon: Icon(Icons.navigation_outlined),
              selectedIcon: Icon(Icons.navigation_rounded, color: AppTheme.primaryGold),
              label: 'Navigate',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_rounded),
              selectedIcon: Icon(Icons.history_toggle_off_rounded, color: AppTheme.primaryGold),
              label: 'History',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded, color: AppTheme.primaryGold),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget? _buildAppBar(
    BuildContext context,
    dynamic partner,
    DutyProvider dutyProv,
    DeliveryProvider deliveryProv,
    AuthProvider authProv,
  ) {
    if (_currentNavIndex == 0) {
      return AppBar(
        titleSpacing: 16,
        elevation: 3,
        shadowColor: Colors.black26,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.luxuryHeaderGradient,
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              padding: const EdgeInsets.all(2.5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.goldRingGradient,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.restaurant_menu_rounded,
                    color: AppTheme.primaryGold,
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          partner?.name.isNotEmpty == true ? partner!.name : 'Delivery Partner',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.lightOnDarkTitle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.gold.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.goldLight.withOpacity(0.5)),
                        ),
                        child: const Text(
                          'FLEET',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.goldLight,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: AppTheme.ratingStar),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${partner?.rating.toStringAsFixed(1) ?? "4.9"} • ${partner?.vehicleType ?? "BIKE"}${(partner?.vehicleNumber ?? "").isNotEmpty ? " (${partner!.vehicleNumber})" : ""}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: AppTheme.lightOnDarkSub),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded, color: AppTheme.goldLight),
            onPressed: () async {
              final navigator = Navigator.of(context);
              if (partner != null) {
                await dutyProv.setStatus(partner, 'OFFLINE');
              }
              deliveryProv.stopPolling();
              await authProv.logout();
              navigator.pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      );
    } else if (_currentNavIndex == 1) {
      return AppBar(
        titleSpacing: 16,
        elevation: 3,
        shadowColor: Colors.black26,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppTheme.luxuryHeaderGradient)),
        title: const Text('Assigned Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.lightOnDarkTitle)),
      );
    } else if (_currentNavIndex == 2) {
      return AppBar(
        titleSpacing: 16,
        elevation: 3,
        shadowColor: Colors.black26,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppTheme.luxuryHeaderGradient)),
        title: const Text('Live Navigation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.lightOnDarkTitle)),
      );
    } else if (_currentNavIndex == 3) {
      return AppBar(
        titleSpacing: 16,
        elevation: 3,
        shadowColor: Colors.black26,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppTheme.luxuryHeaderGradient)),
        title: const Text('Delivery History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.lightOnDarkTitle)),
      );
    } else {
      return AppBar(
        titleSpacing: 16,
        elevation: 3,
        shadowColor: Colors.black26,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppTheme.luxuryHeaderGradient)),
        title: const Text('Profile & Support', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.lightOnDarkTitle)),
      );
    }
  }

  Widget _buildDashboardTab(
    BuildContext context,
    dynamic partner,
    DutyProvider dutyProv,
    DeliveryProvider deliveryProv,
    bool isOnline,
  ) {
    final activeAssignment = deliveryProv.activeAssignment;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          if (partner != null) {
            await deliveryProv.fetchDeliveries(partner.partnerId);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Online / Offline Duty Switch Card
              _buildDutyToggleCard(dutyProv, deliveryProv, partner),
              const SizedBox(height: 14),

              // GPS / Network Connection Alert Banner
              if (!isOnline)
                _buildOfflineWarningBanner()
              else
                _buildOnlineActiveBanner(),
              const SizedBox(height: 14),

              // 4 Quick Metric Cards from visily-delivery-dashboard.jpg
              _buildDashboardMetricGrid(deliveryProv),
              const SizedBox(height: 16),

              // Current Task / Active Delivery Hero Card
              _buildCurrentTaskHero(context, activeAssignment, deliveryProv),
              const SizedBox(height: 16),

              // Incoming Order Alert (if newly ASSIGNED)
              if (activeAssignment != null && activeAssignment.isAssigned) ...[
                _buildIncomingOrderBanner(activeAssignment, deliveryProv),
                const SizedBox(height: 16),
              ],

              // New Assignments Section matching visily-delivery-dashboard.jpg
              _buildNewAssignmentsSection(context, deliveryProv, partner),
              const SizedBox(height: 16),

              // Quick Actions
              Row(
                children: [
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.all(14),
                      onTap: () => setState(() => _currentNavIndex = 3),
                      child: const Row(
                        children: [
                          Icon(Icons.history_rounded, color: AppTheme.primaryGold, size: 22),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Trip History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('Past orders', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.all(14),
                      onTap: () {
                        if (partner != null) {
                          deliveryProv.fetchDeliveries(partner.partnerId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Feed synchronized with backend')),
                          );
                        }
                      },
                      child: const Row(
                        children: [
                          Icon(Icons.sync_rounded, color: AppTheme.primaryDark, size: 22),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Refresh Feed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('Check orders', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
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
    );
  }

  Widget _buildDutyToggleCard(DutyProvider dutyProv, DeliveryProvider deliveryProv, dynamic partner) {
    final isOnline = dutyProv.isOnline || dutyProv.isOnDelivery;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSlate),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: isOnline ? AppTheme.statusSuccess : Colors.grey.shade400,
                  shape: BoxShape.circle,
                  boxShadow: isOnline
                      ? [BoxShadow(color: AppTheme.statusSuccess.withOpacity(0.5), blurRadius: 6, spreadRadius: 1)]
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOnline ? 'Online & Ready for Orders' : 'You are Currently Offline',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.titleHeading),
                  ),
                  Text(
                    isOnline ? 'Accepting deliveries in your zone' : 'Switch ON to receive assignments',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ],
          ),
          Switch(
            value: isOnline,
            activeColor: AppTheme.primaryGold,
            onChanged: (val) async {
              if (partner != null) {
                final newStatus = val ? 'ONLINE' : 'OFFLINE';
                await dutyProv.setStatus(partner, newStatus);
                deliveryProv.startPolling(partner.partnerId, isOnline: val);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: const Row(
        children: [
          Icon(Icons.location_off_rounded, color: Color(0xFFDC2626), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Rider offline. Switch duty status above to connect GPS and receive orders.',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF991B1B), fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineActiveBanner() {
    return ValueListenableBuilder<Map<String, dynamic>>(
      valueListenable: LocationService.locationNotifier,
      builder: (context, loc, _) {
        final lat = (loc['latitude'] as double?) ?? 12.971;
        final lng = (loc['longitude'] as double?) ?? 77.594;
        final coords = '${lat.toStringAsFixed(3)}, ${lng.toStringAsFixed(3)}';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFA7F3D0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF059669), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Online & GPS Active ($coords)',
                    style: const TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFF059669), borderRadius: BorderRadius.circular(4)),
                child: const Text('SYNCED', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDashboardMetricGrid(DeliveryProvider deliveryProv) {
    final stats = deliveryProv.stats;
    final earningsVal = stats != null
        ? stats.todayEarnings
        : deliveryProv.todayTotalEarnings;
    final tripsVal = stats != null
        ? stats.todayDeliveries
        : deliveryProv.todayDeliveriesCount;
    final avgTimeVal = stats != null && stats.avgDeliveryTimeMinutes > 0
        ? '${stats.avgDeliveryTimeMinutes.toStringAsFixed(0)} mins'
        : '20 mins';
    final successVal = stats != null && stats.onTimeRate > 0
        ? '${stats.onTimeRate.toStringAsFixed(0)}%'
        : '100%';

    return Row(
      children: [
        Expanded(child: _buildMetricTile('DAILY EARNINGS', '₹${earningsVal.toStringAsFixed(0)}', null, Icons.account_balance_wallet_outlined, isPositive: true)),
        const SizedBox(width: 8),
        Expanded(child: _buildMetricTile('TOTAL TRIPS', '$tripsVal', null, Icons.navigation_outlined)),
        const SizedBox(width: 8),
        Expanded(child: _buildMetricTile('AVG. TIME', avgTimeVal, null, Icons.timer_outlined)),
        const SizedBox(width: 8),
        Expanded(child: _buildMetricTile('SUCCESS', successVal, null, Icons.verified_outlined, isGreen: true)),
      ],
    );
  }

  Widget _buildMetricTile(String label, String value, String? change, IconData icon, {bool isPositive = false, bool isGreen = false}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderSlate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: isGreen ? AppTheme.statusSuccess : AppTheme.primaryGold),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppTheme.textMuted), maxLines: 1),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.titleHeading), maxLines: 1),
          if (change != null) ...[
            const SizedBox(height: 2),
            Text(change, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isPositive ? AppTheme.statusSuccess : AppTheme.textSecondary)),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentTaskHero(BuildContext context, DeliveryAssignment? activeAssignment, DeliveryProvider deliveryProv) {
    if (activeAssignment == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderSlate),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.two_wheeler_rounded, color: AppTheme.primaryGold, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('No Active Delivery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.titleHeading)),
                      SizedBox(height: 2),
                      Text('Go online or check assigned orders queue to accept a delivery.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryDark,
                  side: const BorderSide(color: AppTheme.primaryGold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: () => setState(() => _currentNavIndex = 1),
                icon: const Icon(Icons.assignment_outlined, size: 16),
                label: const Text('View Available Orders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
          ],
        ),
      );
    }

    final customer = activeAssignment.customerName.isNotEmpty ? activeAssignment.customerName : 'Customer';
    final address = activeAssignment.deliveryAddress.isNotEmpty ? activeAssignment.deliveryAddress : 'Delivery Address';
    final orderId = activeAssignment.orderNumber.isNotEmpty
        ? activeAssignment.orderNumber
        : '#${activeAssignment.orderId.substring(0, activeAssignment.orderId.length > 8 ? 8 : activeAssignment.orderId.length).toUpperCase()}';
    final earnings = '₹${activeAssignment.totalEarning.toStringAsFixed(2)}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSlate),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF7ED),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(activeAssignment.status.replaceAll('_', ' '), style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF7E22CE))),
                    ),
                    const SizedBox(width: 8),
                    Text(orderId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.titleHeading)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 12, color: Colors.amber.shade900),
                      const SizedBox(width: 4),
                      Text('In Progress', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.primaryLight,
                      child: Icon(Icons.person_rounded, color: AppTheme.primaryGold, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(customer, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.titleHeading)),
                          const SizedBox(height: 2),
                          Text(address, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    if (activeAssignment.customerPhone.isNotEmpty)
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: AppTheme.surfaceSlate, shape: BoxShape.circle),
                          child: const Icon(Icons.phone_rounded, color: AppTheme.primaryGold, size: 18),
                        ),
                        onPressed: () => _makeCall(activeAssignment.customerPhone),
                      ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: AppTheme.surfaceSlate, shape: BoxShape.circle),
                        child: const Icon(Icons.near_me_rounded, color: AppTheme.primaryDark, size: 18),
                      ),
                      onPressed: () {
                        setState(() => _currentNavIndex = 2);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, color: AppTheme.borderSlate),
                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('Earnings: ', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        Text(earnings, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.statusSuccess)),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGold,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ActiveDeliveryScreen()),
                        );
                      },
                      child: const Text('Update Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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

  Widget _buildIncomingOrderBanner(DeliveryAssignment assignment, DeliveryProvider deliveryProv) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.goldLight),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_rounded, color: AppTheme.bronze, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('New Assignment Ready!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.titleHeading)),
                Text('${assignment.customerName} • ₹${assignment.totalEarning.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGold,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => OrderDetailsScreen(assignment: assignment)),
              );
            },
            child: const Text('View', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildNewAssignmentsSection(BuildContext context, DeliveryProvider deliveryProv, dynamic partner) {
    final pending = deliveryProv.pendingAssignments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text('New Assignments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.titleHeading)),
                if (pending.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${pending.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                  ),
                ],
              ],
            ),
            InkWell(
              onTap: () => setState(() => _currentNavIndex = 1),
              child: const Text('View All →', style: TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (pending.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderSlate),
            ),
            child: const Center(
              child: Text('No pending assignments at the moment.', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
            ),
          )
        else
          Column(
            children: pending.take(2).map((item) {
              final orderIdText = item.orderNumber.isNotEmpty
                  ? item.orderNumber
                  : '#${item.orderId.substring(0, item.orderId.length > 8 ? 8 : item.orderId.length).toUpperCase()}';
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderSlate),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delivery_dining_rounded, color: AppTheme.primaryGold, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${item.customerName} • $orderIdText', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.titleHeading)),
                          const SizedBox(height: 2),
                          Text(item.deliveryAddress, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₹${item.totalEarning.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppTheme.primaryDark)),
                        const SizedBox(height: 4),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGold,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: const Size(60, 26),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          onPressed: () async {
                            final partnerId = partner?.partnerId;
                            if (partnerId != null) {
                              final messenger = ScaffoldMessenger.of(context);
                              final ok = await deliveryProv.acceptAssignment(item.assignmentId, partnerId);
                              if (ok && mounted) {
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('Order Accepted!')),
                                );
                              }
                            }
                          },
                          child: const Text('Accept', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
