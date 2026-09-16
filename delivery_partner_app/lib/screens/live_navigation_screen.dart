import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../providers/delivery_provider.dart';
import 'customer_info_screen.dart';
import 'delivery_confirmation_screen.dart';
import 'delivery_workflow_screen.dart';

class LiveNavigationScreen extends StatefulWidget {
  final bool showAppBar;
  const LiveNavigationScreen({super.key, this.showAppBar = true});

  @override
  State<LiveNavigationScreen> createState() => _LiveNavigationScreenState();
}

class _LiveNavigationScreenState extends State<LiveNavigationScreen> {
  bool _trafficEnabled = true;

  Future<void> _launchGoogleMaps(String address) async {
    final query = Uri.encodeComponent(address);
    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$query');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open external Google Maps')),
        );
      }
    }
  }

  Future<void> _makeCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deliveryProv = Provider.of<DeliveryProvider>(context);
    final assignment = deliveryProv.activeAssignment;

    final customerName = assignment?.customerName.isNotEmpty == true ? assignment!.customerName : 'Customer';
    final customerPhone = assignment?.customerPhone ?? '';
    final address = assignment?.deliveryAddress.isNotEmpty == true ? assignment!.deliveryAddress : 'Destination Address';
    final orderId = assignment != null
        ? (assignment.orderNumber.isNotEmpty ? assignment.orderNumber : '#${assignment.orderId.substring(0, assignment.orderId.length > 8 ? 8 : assignment.orderId.length).toUpperCase()}')
        : 'Route Navigation';

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: widget.showAppBar
          ? AppBar(
              elevation: 3,
              shadowColor: Colors.black26,
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.luxuryHeaderGradient,
                ),
              ),
              title: Text(
                'Live Navigation ($orderId)',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.lightOnDarkTitle),
              ),
              actions: [
                IconButton(
                  tooltip: 'Delivery Workflow',
                  icon: const Icon(Icons.format_list_bulleted_rounded, color: AppTheme.goldLight),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DeliveryWorkflowScreen()),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            // Turn-by-Turn Instruction Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.espressoDeep, AppTheme.espressoMid],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGold,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assignment != null ? 'Route to $address' : 'Live GPS Navigation Active',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          assignment != null ? 'En-route for customer handover' : 'GPS location synchronized with server',
                          style: const TextStyle(fontSize: 12, color: AppTheme.lightOnDarkSub),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '450 m',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            // Stylized Route Map Canvas
            Expanded(
              child: Stack(
                children: [
                  // Map Background Simulation with streets and pins
                  Container(
                    width: double.infinity,
                    color: const Color(0xFFE8ECEF),
                    child: CustomPaint(
                      painter: _MapRoutePainter(traffic: _trafficEnabled),
                      child: Container(),
                    ),
                  ),

                  // Floating Route Stats Card
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.borderSlate),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('Remaining', '2.4 km', Icons.straighten_rounded),
                          Container(width: 1, height: 28, color: AppTheme.borderSlate),
                          _buildStatItem('Est. Time', '8 mins', Icons.access_time_filled_rounded),
                          Container(width: 1, height: 28, color: AppTheme.borderSlate),
                          _buildStatItem('Traffic', 'Fast', Icons.traffic_rounded, isGreen: true),
                        ],
                      ),
                    ),
                  ),

                  // Floating Map Controls (Recenter, Traffic toggle)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Column(
                      children: [
                        FloatingActionButton.small(
                          heroTag: 'traffic_toggle',
                          backgroundColor: Colors.white,
                          foregroundColor: _trafficEnabled ? AppTheme.primaryGold : Colors.grey,
                          onPressed: () => setState(() => _trafficEnabled = !_trafficEnabled),
                          child: const Icon(Icons.layers_rounded),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: 'recenter_gps',
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.titleHeading,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Recentered to rider GPS location')),
                            );
                          },
                          child: const Icon(Icons.my_location_rounded),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Customer & Navigation Action Panel
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -3)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Customer Header
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
                            Text(
                              customerName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.titleHeading),
                            ),
                            Text(
                              '$orderId • Sector 7G',
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Call Customer',
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppTheme.surfaceSlate,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.phone_rounded, color: AppTheme.primaryGold, size: 18),
                        ),
                        onPressed: () => _makeCall(customerPhone),
                      ),
                      IconButton(
                        tooltip: 'Customer Info & Notes',
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppTheme.surfaceSlate,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.note_alt_outlined, color: AppTheme.titleHeading, size: 18),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerInfoScreen(
                                customerName: customerName,
                                phone: customerPhone,
                                address: address,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Destination address snippet
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceSlate,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 16, color: AppTheme.primaryDark),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            address,
                            style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Dual Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.titleHeading,
                            side: const BorderSide(color: AppTheme.borderSlate),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _launchGoogleMaps(address),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.directions_rounded, size: 18, color: AppTheme.primaryDark),
                              SizedBox(width: 6),
                              Text('Google Maps', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppTheme.imperialActionGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const DeliveryConfirmationScreen(),
                                ),
                              );
                            },
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_outline_rounded, size: 18),
                                SizedBox(width: 6),
                                Text('I Have Arrived', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
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
    );
  }

  Widget _buildStatItem(String title, String val, IconData icon, {bool isGreen = false}) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: isGreen ? AppTheme.statusSuccess : AppTheme.textMuted),
            const SizedBox(width: 4),
            Text(title, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          val,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isGreen ? AppTheme.statusSuccess : AppTheme.titleHeading,
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────
// Custom Map Simulation Painter for crisp vector route rendering
// ────────────────────────────────────────────────────────────
class _MapRoutePainter extends CustomPainter {
  final bool traffic;
  _MapRoutePainter({required this.traffic});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFF0F3F6);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Draw street grid lines
    final streetPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;

    final thinStreetPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    // Horizontal roads
    canvas.drawLine(Offset(0, size.height * 0.25), Offset(size.width, size.height * 0.25), streetPaint);
    canvas.drawLine(Offset(0, size.height * 0.60), Offset(size.width, size.height * 0.60), streetPaint);
    canvas.drawLine(Offset(0, size.height * 0.85), Offset(size.width, size.height * 0.85), thinStreetPaint);

    // Vertical roads
    canvas.drawLine(Offset(size.width * 0.25, 0), Offset(size.width * 0.25, size.height), streetPaint);
    canvas.drawLine(Offset(size.width * 0.70, 0), Offset(size.width * 0.70, size.height), streetPaint);

    // Route Path
    final routePath = Path();
    routePath.moveTo(size.width * 0.25, size.height * 0.25);
    routePath.lineTo(size.width * 0.25, size.height * 0.60);
    routePath.lineTo(size.width * 0.70, size.height * 0.60);
    routePath.lineTo(size.width * 0.70, size.height * 0.40);

    // Route casing
    final casingPaint = Paint()
      ..color = const Color(0xFF8C581E).withOpacity(0.3)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(routePath, casingPaint);

    // Active Route line
    final activeRoutePaint = Paint()
      ..color = AppTheme.primaryGold
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(routePath, activeRoutePaint);

    // Restaurant Marker (Start)
    final storePaint = Paint()..color = AppTheme.primaryDark;
    canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.25), 9, storePaint);
    final storeInner = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.25), 4, storeInner);

    // Rider Marker (Current position along the route)
    final riderBg = Paint()..color = const Color(0xFF261208);
    canvas.drawCircle(Offset(size.width * 0.45, size.height * 0.60), 12, riderBg);
    final riderCenter = Paint()..color = AppTheme.goldLight;
    canvas.drawCircle(Offset(size.width * 0.45, size.height * 0.60), 6, riderCenter);

    // Destination Pin (Customer)
    final destBg = Paint()..color = AppTheme.statusSuccess;
    canvas.drawCircle(Offset(size.width * 0.70, size.height * 0.40), 10, destBg);
    final destInner = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(size.width * 0.70, size.height * 0.40), 4, destInner);
  }

  @override
  bool shouldRepaint(covariant _MapRoutePainter oldDelegate) => oldDelegate.traffic != traffic;
}
