import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';

class CustomerInfoScreen extends StatelessWidget {
  final String customerName;
  final String phone;
  final String address;
  final String? deliveryNotes;

  const CustomerInfoScreen({
    super.key,
    required this.customerName,
    required this.phone,
    required this.address,
    this.deliveryNotes,
  });

  Future<void> _makeCall(BuildContext context) async {
    if (phone.isEmpty) return;
    final clean = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cannot dial $clean')));
      }
    }
  }

  Future<void> _sendMessage(BuildContext context) async {
    if (phone.isEmpty) return;
    final clean = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('sms:$clean?body=Hello%20$customerName,%20this%20is%20your%20Spice%20Haven%20delivery%20partner.');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot open messaging app')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = customerName.isNotEmpty ? customerName : 'Customer';
    final displayPhone = phone.isNotEmpty ? phone : 'No contact phone provided';
    final displayAddress = address.isNotEmpty ? address : 'Address details provided on arrival';

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
          'Customer Information',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.lightOnDarkTitle),
        ),
        actions: [
          IconButton(
            tooltip: 'Copy Info',
            icon: const Icon(Icons.copy_rounded, color: AppTheme.goldLight),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: '$displayName\n$displayPhone\n$displayAddress'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Customer information copied to clipboard')),
              );
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
              // Customer Profile Card
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
                            displayName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.titleHeading),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            displayPhone,
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'VERIFIED RECIPIENT',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Dual Action Buttons: Call Customer & Send Message
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.imperialActionGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.phone_rounded, size: 18),
                        label: const Text('Call Customer', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: phone.isNotEmpty ? () => _makeCall(context) : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.statusSuccess,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                      label: const Text('Send Message', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: phone.isNotEmpty ? () => _sendMessage(context) : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Delivery Location Section
              const Text(
                'Delivery Location',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.titleHeading),
              ),
              const SizedBox(height: 10),

              // Full Address Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderSlate),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.location_on_rounded, color: AppTheme.primaryGold, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('DESTINATION ADDRESS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                          const SizedBox(height: 4),
                          Text(displayAddress, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.titleHeading, height: 1.3)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Delivery Instructions Section
              const Text(
                'Delivery Instructions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.titleHeading),
              ),
              const SizedBox(height: 10),

              // Order Notes Card
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
                    const Row(
                      children: [
                        Icon(Icons.notes_rounded, color: AppTheme.primaryGold, size: 18),
                        SizedBox(width: 8),
                        Text('SPECIAL INSTRUCTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      deliveryNotes != null && deliveryNotes!.trim().isNotEmpty
                          ? deliveryNotes!
                          : 'Direct drop-off at specified delivery location. Call customer upon arrival.',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.4),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Bottom Return Button
              Container(
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Return to Active Delivery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
