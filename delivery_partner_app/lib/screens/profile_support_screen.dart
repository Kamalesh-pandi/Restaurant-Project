import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/duty_provider.dart';
import '../providers/delivery_provider.dart';
import '../widgets/server_config_dialog.dart';
import 'login_screen.dart';
import 'performance_analytics_screen.dart';

class ProfileSupportScreen extends StatelessWidget {
  final bool showAppBar;
  const ProfileSupportScreen({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context) {
    final authProv = Provider.of<AuthProvider>(context);
    final dutyProv = Provider.of<DutyProvider>(context);
    final deliveryProv = Provider.of<DeliveryProvider>(context);
    final partner = authProv.partner;

    final name = partner?.name.isNotEmpty == true ? partner!.name : 'Delivery Partner';
    final partnerId = partner != null ? '#${partner.partnerId.substring(0, partner.partnerId.length > 8 ? 8 : partner.partnerId.length).toUpperCase()}' : '';
    final rating = partner?.rating != null ? partner!.rating.toStringAsFixed(1) : (deliveryProv.stats?.rating.toStringAsFixed(1) ?? '5.0');
    final isOnline = dutyProv.isOnline || dutyProv.isOnDelivery;

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: showAppBar
          ? AppBar(
              elevation: 3,
              shadowColor: Colors.black26,
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.luxuryHeaderGradient,
                ),
              ),
              title: const Text(
                'Profile & Support',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.lightOnDarkTitle),
              ),
              actions: [
                IconButton(
                  tooltip: 'Notifications',
                  icon: const Icon(Icons.notifications_outlined, color: AppTheme.goldLight),
                  onPressed: () {},
                ),
                const SizedBox(width: 8),
              ],
            )
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Partner Header & Online Status Toggle Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderSlate),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              const CircleAvatar(
                                radius: 30,
                                backgroundColor: AppTheme.primaryLight,
                                child: Icon(Icons.person_rounded, color: AppTheme.primaryGold, size: 38),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: isOnline ? AppTheme.statusSuccess : Colors.grey,
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
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.titleHeading),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  partnerId.isNotEmpty ? 'Partner ID: $partnerId' : 'Partner Account',
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryLight,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'GOLD PARTNER',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.primaryDark),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceSlate,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.star_rounded, size: 13, color: AppTheme.ratingStar),
                                          const SizedBox(width: 2),
                                          Text(rating, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                        ],
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
                    const Divider(height: 1, color: AppTheme.borderSlate),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: isOnline ? AppTheme.statusSuccess : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isOnline ? 'Online & Available for Orders' : 'Offline (Not receiving orders)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isOnline ? AppTheme.titleHeading : AppTheme.textMuted,
                                ),
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
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // APP STATUS Section
              const Text(
                'APP STATUS',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textMuted, letterSpacing: 0.5),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildStatusWidget(Icons.near_me_rounded, 'GPS', 'High Accuracy')),
                  const SizedBox(width: 10),
                  Expanded(child: _buildStatusWidget(Icons.battery_charging_full_rounded, 'BATTERY', '84%')),
                  const SizedBox(width: 10),
                  Expanded(child: _buildStatusWidget(Icons.wifi_rounded, 'NETWORK', 'Excellent')),
                ],
              ),

              const SizedBox(height: 20),

              // Account & Preferences
              const Text(
                'Account & Preferences',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.titleHeading),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderSlate),
                ),
                child: Column(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.person_outline_rounded,
                      title: 'Personal Information',
                      subtitle: 'Manage KYC, Address, and Bank accounts',
                      onTap: () {},
                    ),
                    const Divider(height: 1, color: AppTheme.borderSubtle),
                    _buildSettingsTile(
                      icon: Icons.security_outlined,
                      title: 'Permissions & Tracking',
                      subtitle: 'GPS, Camera, and Push Notifications',
                      onTap: () {},
                    ),
                    const Divider(height: 1, color: AppTheme.borderSubtle),
                    _buildSettingsTile(
                      icon: Icons.settings_outlined,
                      title: 'App Settings',
                      subtitle: 'Language, Audio Alerts, Dark Mode',
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Earnings & Performance Link Card
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PerformanceAnalyticsScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
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
                        child: const Icon(Icons.insights_rounded, color: AppTheme.primaryGold, size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Earnings & Performance',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.titleHeading),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'View your weekly achievements & ratings',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Support Center Card
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
                      children: [
                        Icon(Icons.support_agent_rounded, color: AppTheme.primaryGold, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Support Center',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.titleHeading),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Need help with an active order, settlement, or vehicle breakdown?',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.titleHeading,
                              side: const BorderSide(color: AppTheme.borderSlate),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: const Icon(Icons.phone_rounded, size: 16, color: AppTheme.primaryGold),
                            label: const Text('Call Support', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Dialing 24/7 Rider Fleet Support...')),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.titleHeading,
                              side: const BorderSide(color: AppTheme.borderSlate),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AppTheme.statusSuccess),
                            label: const Text('Chat Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Starting live support chat session...')),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.surfaceSlate,
                          foregroundColor: AppTheme.titleHeading,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Opening Rider Help Center & FAQs...')),
                          );
                        },
                        child: const Text('View Help Articles & FAQs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Server Configuration Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderSlate),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGold.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.dns_rounded, color: AppTheme.primaryGold, size: 20),
                  ),
                  title: const Text(
                    'Server Endpoint',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.titleHeading),
                  ),
                  subtitle: Text(
                    ApiConfig.baseUrl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
                  onTap: () => ServerConfigDialog.show(context),
                ),
              ),

              const SizedBox(height: 24),

              // Logout Button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.statusError,
                  side: BorderSide(color: AppTheme.statusError.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Logout from Spice Haven Fleet', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  if (partner != null) {
                    await dutyProv.setStatus(partner, 'OFFLINE');
                  }
                  deliveryProv.stopPolling();
                  await authProv.logout();
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),

              const SizedBox(height: 14),
              const Center(
                child: Text(
                  'APP VERSION 2.4.0 (BUILD 882)',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 0.5),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusWidget(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSlate),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryGold),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.titleHeading), maxLines: 1),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceSlate,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: AppTheme.titleHeading),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.titleHeading)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppTheme.textMuted),
      onTap: onTap,
    );
  }
}
