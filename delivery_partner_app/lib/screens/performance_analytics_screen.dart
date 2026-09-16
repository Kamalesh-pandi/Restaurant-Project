import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/delivery_provider.dart';

class PerformanceAnalyticsScreen extends StatelessWidget {
  const PerformanceAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProv = Provider.of<AuthProvider>(context);
    final deliveryProv = Provider.of<DeliveryProvider>(context);
    final partner = authProv.partner;
    final stats = deliveryProv.stats;

    final name = partner?.name.isNotEmpty == true ? partner!.name : 'Delivery Partner';
    final rating = partner?.rating != null
        ? partner!.rating.toStringAsFixed(2)
        : (stats != null ? stats.rating.toStringAsFixed(2) : '5.00');

    final todayEarnings = stats != null
        ? stats.todayEarnings
        : deliveryProv.todayTotalEarnings;

    final todayDeliveries = stats != null
        ? stats.todayDeliveries
        : deliveryProv.todayDeliveriesCount;

    final weeklyDeliveries = stats != null
        ? stats.weeklyDeliveries
        : deliveryProv.completedDeliveries.length;

    final avgTime = stats != null && stats.avgDeliveryTimeMinutes > 0
        ? '${stats.avgDeliveryTimeMinutes.toStringAsFixed(1)} min'
        : '18 min';

    final onTimeRate = stats != null && stats.onTimeRate > 0
        ? stats.onTimeRate
        : 100.0;

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
          'My Performance',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.lightOnDarkTitle),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Stats',
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.goldLight),
            onPressed: () {
              if (partner != null) {
                deliveryProv.fetchPartnerStats(partner.partnerId);
                deliveryProv.fetchDeliveries(partner.partnerId);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Rider Overview Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderSlate),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          backgroundColor: AppTheme.primaryLight,
                          child: Icon(Icons.person_rounded, color: AppTheme.primaryGold, size: 34),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppTheme.statusSuccess,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.titleHeading),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'PREMIUM RIDER',
                                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppTheme.primaryDark),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.star_rounded, size: 14, color: AppTheme.ratingStar),
                              const SizedBox(width: 2),
                              Text(rating, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('TODAY\'S PAY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                        const SizedBox(height: 2),
                        Text(
                          '₹${todayEarnings.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.primaryDark),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 4 Metrics Grid (2x2)
              Row(
                children: [
                  Expanded(child: _buildMetricCard('Today\'s Deliveries', '$todayDeliveries', null, Icons.check_circle_outline_rounded, isPositive: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildMetricCard('Weekly Volume', '$weeklyDeliveries', null, Icons.trending_up_rounded, isPositive: true)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildMetricCard('Avg. Delivery', avgTime, null, Icons.access_time_rounded, isPositive: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildMetricCard('Success Rate', '${onTimeRate.toStringAsFixed(0)}%', null, Icons.verified_rounded, isPositive: true)),
                ],
              ),

              const SizedBox(height: 20),

              // Weekly Trend Bar Chart Card
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
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Weekly Activity',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.titleHeading),
                            ),
                            Text(
                              'Deliveries completed',
                              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceSlate,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.calendar_today_rounded, size: 12, color: AppTheme.textSecondary),
                              SizedBox(width: 6),
                              Text('This Week', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.titleHeading)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Custom Bar Chart
                    SizedBox(
                      height: 140,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildDayBar('Mon', (weeklyDeliveries * 0.1).round(), weeklyDeliveries > 0 ? weeklyDeliveries : 10),
                          _buildDayBar('Tue', (weeklyDeliveries * 0.15).round(), weeklyDeliveries > 0 ? weeklyDeliveries : 10),
                          _buildDayBar('Wed', (weeklyDeliveries * 0.12).round(), weeklyDeliveries > 0 ? weeklyDeliveries : 10),
                          _buildDayBar('Thu', (weeklyDeliveries * 0.18).round(), weeklyDeliveries > 0 ? weeklyDeliveries : 10),
                          _buildDayBar('Fri', (weeklyDeliveries * 0.25).round(), weeklyDeliveries > 0 ? weeklyDeliveries : 10, isHighest: true),
                          _buildDayBar('Sat', (weeklyDeliveries * 0.20).round(), weeklyDeliveries > 0 ? weeklyDeliveries : 10),
                          _buildDayBar('Sun', todayDeliveries, weeklyDeliveries > 0 ? weeklyDeliveries : 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Success & On-Time Progress Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderSlate),
                ),
                child: Column(
                  children: [
                    _buildProgressBarItem('Delivery Success Rate', '${onTimeRate.toStringAsFixed(1)}%', 'Target: 95.0%', onTimeRate / 100, Icons.verified_outlined),
                    const Divider(height: 24, color: AppTheme.borderSlate),
                    _buildProgressBarItem('Customer Satisfaction', '${(rating.isNotEmpty ? double.tryParse(rating) ?? 5.0 : 5.0).toStringAsFixed(1)} / 5.0', 'Target: 4.5 / 5.0', 0.98, Icons.sentiment_very_satisfied_rounded),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Achievements Section
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Achievements & Badges',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.titleHeading),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildAchievementItem('Punctual Rider', 'Fast Handover', Icons.bolt_rounded, AppTheme.primaryGold)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildAchievementItem('Top Rating', 'Gold Service', Icons.star_rounded, const Color(0xFF6366F1))),
                  const SizedBox(width: 10),
                  Expanded(child: _buildAchievementItem('Reliable Partner', 'Safe Deliveries', Icons.verified_user_rounded, AppTheme.statusSuccess)),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String val, String? change, IconData icon, {bool isPositive = false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderSlate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 20, color: AppTheme.primaryGold),
              if (change != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isPositive ? const Color(0xFFECFDF5) : AppTheme.surfaceSlate,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    change,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isPositive ? AppTheme.statusSuccess : AppTheme.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          const SizedBox(height: 2),
          Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.titleHeading)),
        ],
      ),
    );
  }

  Widget _buildDayBar(String day, int count, int max, {bool isHighest = false}) {
    final effectiveMax = max > 0 ? max : 1;
    final heightRatio = (count / effectiveMax).clamp(0.05, 1.0);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('$count', style: TextStyle(fontSize: 10, color: isHighest ? AppTheme.primaryDark : AppTheme.textMuted, fontWeight: isHighest ? FontWeight.bold : FontWeight.normal)),
        const SizedBox(height: 4),
        Container(
          width: 24,
          height: 100 * heightRatio,
          decoration: BoxDecoration(
            color: isHighest ? AppTheme.primaryGold : const Color(0xFF6366F1).withOpacity(0.7),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 8),
        Text(day, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildProgressBarItem(String title, String val, String target, double progress, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppTheme.primaryGold),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.titleHeading)),
              ],
            ),
            Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryDark)),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: AppTheme.surfaceSlate,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGold),
          ),
        ),
        const SizedBox(height: 6),
        Text(target, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
      ],
    );
  }

  Widget _buildAchievementItem(String title, String desc, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSlate),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.titleHeading), textAlign: TextAlign.center, maxLines: 1),
          const SizedBox(height: 2),
          Text(desc, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted), textAlign: TextAlign.center, maxLines: 1),
        ],
      ),
    );
  }
}
