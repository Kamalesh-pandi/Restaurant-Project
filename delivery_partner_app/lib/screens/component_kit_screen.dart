import 'package:flutter/material.dart';
import '../config/theme.dart';

class ComponentKitScreen extends StatelessWidget {
  const ComponentKitScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          'UI Component Library',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.lightOnDarkTitle),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Intro
              const Text(
                'Spice Haven Fleet Kit',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.titleHeading),
              ),
              const SizedBox(height: 4),
              const Text(
                'Modular components designed for high-efficiency culinary delivery operations.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),

              // Section 1: Notifications & Alerts
              _buildSectionTitle('NOTIFICATIONS & ALERTS'),
              const SizedBox(height: 10),
              // Warning Alert
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'GPS Connection Lost',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF991B1B)),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'You are currently offline. Enable location services to receive new order assignments.',
                            style: TextStyle(fontSize: 11, color: Color(0xFFB91C1C)),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () {},
                            child: const Text(
                              'Enable GPS Now →',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Success Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, color: Color(0xFF059669), size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Online & GPS Active',
                      style: TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Section 2: Interactive Order Card
              _buildSectionTitle('INTERACTIVE ORDER CARDS'),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderSlate),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('SWIGGY  #ORD-1024', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFC2410C))),
                          Text('12 mins left', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFC2410C))),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Johnathan Miller', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    SizedBox(height: 2),
                                    Text('122 Baker St, London', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(color: AppTheme.surfaceSlate, shape: BoxShape.circle),
                                  child: const Icon(Icons.phone_rounded, color: AppTheme.primaryGold, size: 16),
                                ),
                                onPressed: () {},
                              ),
                            ],
                          ),
                          const Divider(height: 20, color: AppTheme.borderSlate),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Text('Earnings: ', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                  Text('₹85.00', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.statusSuccess)),
                                ],
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryGold,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () {},
                                child: const Text('Accept Task', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Section 3: Dashboard Widgets
              _buildSectionTitle('DASHBOARD WIDGETS'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildSmallWidget('DAILY EARNINGS', '₹124.50', '+12%', Icons.account_balance_wallet_outlined)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildSmallWidget('TOTAL TRIPS', '18', null, Icons.timer_outlined)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildSmallWidget('RATING', '4.9 ★', null, Icons.star_outline_rounded)),
                ],
              ),

              const SizedBox(height: 24),

              // Section 4: Performance Indicators
              _buildSectionTitle('PERFORMANCE INDICATORS'),
              const SizedBox(height: 10),
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
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Today\'s Performance', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                            SizedBox(height: 2),
                            Text('94% Success', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppTheme.titleHeading)),
                          ],
                        ),
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Color(0xFFECFDF5),
                          child: Icon(Icons.check_rounded, color: AppTheme.statusSuccess, size: 24),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Deliveries Completed', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        Text('12/13', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(
                        value: 0.92,
                        minHeight: 8,
                        backgroundColor: AppTheme.surfaceSlate,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(Icons.trending_up_rounded, size: 14, color: AppTheme.statusSuccess),
                        SizedBox(width: 4),
                        Text('Up 5.2% from yesterday', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.statusSuccess)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Section 5: Avatar & Identity
              _buildSectionTitle('AVATAR & IDENTITY'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderSlate),
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          backgroundColor: AppTheme.primaryLight,
                          child: Icon(Icons.person_rounded, color: AppTheme.primaryGold, size: 30),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppTheme.statusSuccess,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Marcus Sterling', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.titleHeading)),
                        SizedBox(height: 2),
                        Text('Verified Partner since 2023', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Section 6: Loading Skeletons
              _buildSectionTitle('LOADING SKELETONS'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderSlate),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSkeletonBar(double.infinity, 14),
                    const SizedBox(height: 8),
                    _buildSkeletonBar(200, 12),
                    const SizedBox(height: 8),
                    _buildSkeletonBar(120, 12),
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

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(width: 3, height: 14, color: AppTheme.primaryGold),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textMuted, letterSpacing: 0.5),
        ),
      ],
    );
  }

  Widget _buildSmallWidget(String label, String val, String? change, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderSlate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryGold),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
          const SizedBox(height: 2),
          Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.titleHeading)),
          if (change != null) ...[
            const SizedBox(height: 2),
            Text(change, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.statusSuccess)),
          ],
        ],
      ),
    );
  }

  Widget _buildSkeletonBar(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
