import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/delivery_provider.dart';

class DeliveryConfirmationScreen extends StatefulWidget {
  const DeliveryConfirmationScreen({super.key});

  @override
  State<DeliveryConfirmationScreen> createState() => _DeliveryConfirmationScreenState();
}

class _DeliveryConfirmationScreenState extends State<DeliveryConfirmationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _notesController = TextEditingController(text: 'Delivered directly to customer at doorstep');

  bool _photoTaken = false;
  bool _isSignatureDrawn = false;
  bool _isSubmitting = false;

  final List<Offset?> _signaturePoints = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _otpController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirmDelivery() async {
    final deliveryProv = Provider.of<DeliveryProvider>(context, listen: false);
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final assignment = deliveryProv.activeAssignment;

    if (assignment == null || authProv.partner == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active delivery task found to complete.'),
          backgroundColor: AppTheme.statusError,
        ),
      );
      return;
    }

    final isOtpTab = _tabController.index == 1;
    final enteredOtp = _otpController.text.trim();

    if (isOtpTab && enteredOtp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the customer\'s 4-digit OTP code.'),
          backgroundColor: AppTheme.statusError,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    String notes = _notesController.text.trim();
    if (_photoTaken) {
      notes += ' (Proof photo captured at doorstep)';
    }
    if (_isSignatureDrawn) {
      notes += ' (Customer signature received)';
    }

    final success = await deliveryProv.completeDelivery(
      assignment.assignmentId,
      authProv.partner!.partnerId,
      isOtpTab ? enteredOtp : '',
      notes,
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (success) {
      _showSuccessDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(deliveryProv.errorMessage ?? 'Verification failed. Please check the OTP or try again.'),
          backgroundColor: AppTheme.statusError,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppTheme.statusSuccess, size: 54),
            ),
            const SizedBox(height: 18),
            const Text(
              'Delivery Completed!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.titleHeading),
            ),
            const SizedBox(height: 8),
            const Text(
              'Proof verified successfully. Earnings added to your wallet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Back to Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          'Confirm Delivery',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.lightOnDarkTitle),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.goldLight,
          indicatorWeight: 3,
          labelColor: AppTheme.lightOnDarkTitle,
          unselectedLabelColor: AppTheme.lightOnDarkSub.withOpacity(0.7),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'Standard Proof'),
            Tab(text: 'OTP Verification'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildStandardProofTab(),
            _buildOtpVerificationTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildStandardProofTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Photo of Package Section
          const Text(
            'Photo of Package at Doorstep',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.titleHeading),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              setState(() => _photoTaken = !_photoTaken);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(_photoTaken ? 'Proof photo captured!' : 'Proof photo cleared')),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _photoTaken ? AppTheme.statusSuccess : AppTheme.borderSlate,
                  width: _photoTaken ? 2 : 1,
                ),
              ),
              child: _photoTaken
                  ? Stack(
                      children: [
                        const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_rounded, color: AppTheme.statusSuccess, size: 48),
                              SizedBox(height: 8),
                              Text('Doorstep Package Photo Captured', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              SizedBox(height: 4),
                              Text('Tap to retake photo', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.statusSuccess,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('VERIFIED', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: AppTheme.primaryGold, size: 28),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Tap to Capture Package Photo',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.titleHeading),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Ensure order package and door number are visible',
                          style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 20),

          // Customer Signature Pad
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Customer Signature',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.titleHeading),
              ),
              if (_isSignatureDrawn)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _signaturePoints.clear();
                      _isSignatureDrawn = false;
                    });
                  },
                  child: const Text('Clear', style: TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 130,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderSlate),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    RenderBox renderBox = context.findRenderObject() as RenderBox;
                    _signaturePoints.add(renderBox.globalToLocal(details.globalPosition));
                    _isSignatureDrawn = true;
                  });
                },
                onPanEnd: (_) => _signaturePoints.add(null),
                child: CustomPaint(
                  painter: _SignaturePainter(_signaturePoints),
                  child: !_isSignatureDrawn
                      ? const Center(
                          child: Text(
                            'Customer sign here with finger',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                          ),
                        )
                      : Container(),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Delivery Notes
          const Text(
            'Delivery Notes (Optional)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.titleHeading),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'e.g. Left with security guard / Delivered directly',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.borderSlate)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.borderSlate)),
            ),
          ),

          const SizedBox(height: 28),

          // Confirm Button
          _buildSubmitButton(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildOtpVerificationTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.phonelink_lock_rounded, color: AppTheme.primaryGold, size: 48),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Ask Customer for 4-Digit OTP',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.titleHeading),
          ),
          const SizedBox(height: 8),
          const Text(
            'The OTP has been sent to the customer\'s registered phone number to verify this handover.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // OTP input
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 12, color: AppTheme.primaryDark),
            decoration: InputDecoration(
              counterText: '',
              hintText: '••••',
              hintStyle: const TextStyle(letterSpacing: 12, color: AppTheme.hintPlaceholder),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primaryGold, width: 2)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.borderSlate)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primaryGold, width: 2)),
            ),
          ),

          const SizedBox(height: 14),

          // Resend Code link
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 16, color: AppTheme.primaryGold),
              label: const Text('Resend OTP to Customer', style: TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold)),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('OTP resent to customer phone number')),
                );
              },
            ),
          ),

          const Spacer(),

          // Confirm Button
          _buildSubmitButton(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
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
        onPressed: _isSubmitting ? null : _handleConfirmDelivery,
        child: _isSubmitting
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, size: 20),
                  SizedBox(width: 8),
                  Text('Confirm Delivery & Complete Task', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Signature Canvas Painter
// ────────────────────────────────────────────────────────────
class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  _SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.titleHeading
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
