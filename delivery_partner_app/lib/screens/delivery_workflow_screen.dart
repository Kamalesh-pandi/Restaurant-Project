import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/delivery_provider.dart';
import 'customer_info_screen.dart';
import 'delivery_confirmation_screen.dart';
import 'live_navigation_screen.dart';

class DeliveryWorkflowScreen extends StatefulWidget {
  const DeliveryWorkflowScreen({super.key});

  @override
  State<DeliveryWorkflowScreen> createState() => _DeliveryWorkflowScreenState();
}

class _DeliveryWorkflowScreenState extends State<DeliveryWorkflowScreen> {
  bool _isUpdating = false;

  int _getStepFromStatus(String status) {
    switch (status) {
      case 'ASSIGNED':
        return 0;
      case 'ACCEPTED':
        return 1;
      case 'PICKED_UP':
        return 2;
      case 'IN_TRANSIT':
        return 3;
      case 'ARRIVED':
        return 4;
      case 'DELIVERED':
        return 5;
      default:
        return 1;
    }
  }

  final List<Map<String, String>> _workflowSteps = [
    {
      'title': 'Order Assigned',
      'subtitle': 'Order allocated to delivery partner',
      'time': 'Stage 1',
    },
    {
      'title': 'Accepted & Heading to Kitchen',
      'subtitle': 'Navigate to restaurant dispatch counter',
      'time': 'Stage 2',
    },
    {
      'title': 'Order Picked Up',
      'subtitle': 'Verified items & departed restaurant',
      'time': 'Stage 3',
    },
    {
      'title': 'Out for Delivery',
      'subtitle': 'En-route to customer destination',
      'time': 'Stage 4',
    },
    {
      'title': 'Arrived at Destination',
      'subtitle': 'At customer building / doorstep',
      'time': 'Stage 5',
    },
    {
      'title': 'Customer Handover',
      'subtitle': 'Verify OTP or take package photo',
      'time': 'Final Stage',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final deliveryProv = Provider.of<DeliveryProvider>(context);
    final authProv = Provider.of<AuthProvider>(context);
    final assignment = deliveryProv.activeAssignment;

    if (assignment == null) {
      return Scaffold(
        backgroundColor: AppTheme.appBackground,
        appBar: AppBar(
          title: const Text('Delivery Workflow', style: TextStyle(color: AppTheme.lightOnDarkTitle)),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.luxuryHeaderGradient,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.two_wheeler_rounded, size: 48, color: AppTheme.primaryGold),
                ),
                const SizedBox(height: 18),
                const Text(
                  'No Active Delivery Workflow',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.titleHeading),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Accept an assigned order to initiate the live multi-stage delivery workflow.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGold,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Return to Home Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentStepIndex = _getStepFromStatus(assignment.status);

    final customerName = assignment.customerName.isNotEmpty ? assignment.customerName : 'Customer';
    final customerPhone = assignment.customerPhone;
    final address = assignment.deliveryAddress;
    final orderId = assignment.orderNumber.isNotEmpty
        ? assignment.orderNumber
        : '#${assignment.orderId.substring(0, assignment.orderId.length > 8 ? 8 : assignment.orderId.length).toUpperCase()}';

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
          'Workflow $orderId',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.lightOnDarkTitle),
        ),
        actions: [
          IconButton(
            tooltip: 'Live Map',
            icon: const Icon(Icons.map_rounded, color: AppTheme.goldLight),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LiveNavigationScreen()),
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
              // Delivery Target Summary Card
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
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.primaryLight,
                      child: Icon(Icons.delivery_dining_rounded, color: AppTheme.primaryGold, size: 28),
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
                            address,
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'View Customer Info',
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppTheme.surfaceSlate,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.info_outline_rounded, color: AppTheme.primaryGold, size: 18),
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
              ),

              const SizedBox(height: 16),

              // Multi-stage Timeline Stepper Card
              Container(
                padding: const EdgeInsets.all(18),
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
                          'DELIVERY PROGRESS',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 0.5),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Step ${currentStepIndex + 1} of 6',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    for (int i = 0; i < _workflowSteps.length; i++)
                      _buildStepItem(
                        index: i,
                        currentStepIndex: currentStepIndex,
                        title: _workflowSteps[i]['title']!,
                        subtitle: _workflowSteps[i]['subtitle']!,
                        time: _workflowSteps[i]['time']!,
                        isLast: i == _workflowSteps.length - 1,
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Action CTA Button based on current stage
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
                  onPressed: _isUpdating
                      ? null
                      : () async {
                          final partnerId = authProv.partner?.partnerId;
                          if (partnerId == null) return;

                          if (currentStepIndex <= 1) {
                            // Confirm pickup from kitchen
                            setState(() => _isUpdating = true);
                            await deliveryProv.pickupOrder(assignment.assignmentId, partnerId);
                            if (mounted) setState(() => _isUpdating = false);
                          } else {
                            // Navigate to confirmation screen for OTP or Proof
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DeliveryConfirmationScreen(),
                              ),
                            );
                          }
                        },
                  child: _isUpdating
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              currentStepIndex >= 4 ? Icons.verified_user_rounded : Icons.arrow_forward_rounded,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              currentStepIndex <= 1
                                  ? 'Confirm Pickup at Kitchen'
                                  : currentStepIndex < 4
                                      ? 'Mark Arrived at Doorstep'
                                      : 'Complete Customer Handover',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 12),

              // Secondary Actions (Support / Failed)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.statusError,
                        side: BorderSide(color: AppTheme.statusError.withOpacity(0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.report_problem_outlined, size: 18),
                      label: const Text('Report Issue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: () => _showReportIssueDialog(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.titleHeading,
                        side: const BorderSide(color: AppTheme.borderSlate),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.headset_mic_rounded, size: 18, color: AppTheme.primaryGold),
                      label: const Text('Fleet Support', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Contacting Spice Haven Fleet Support...')),
                        );
                      },
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

  Widget _buildStepItem({
    required int index,
    required int currentStepIndex,
    required String title,
    required String subtitle,
    required String time,
    required bool isLast,
  }) {
    final isCompleted = index < currentStepIndex;
    final isCurrent = index == currentStepIndex;

    Color circleBg = AppTheme.surfaceSlate;
    Color iconColor = AppTheme.textMuted;
    Widget centerWidget = Text(
      '${index + 1}',
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: iconColor),
    );

    if (isCompleted) {
      circleBg = AppTheme.statusSuccess;
      centerWidget = const Icon(Icons.check_rounded, color: Colors.white, size: 16);
    } else if (isCurrent) {
      circleBg = AppTheme.primaryGold;
      centerWidget = Text(
        '${index + 1}',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: circleBg,
                shape: BoxShape.circle,
                border: isCurrent ? Border.all(color: AppTheme.goldLight, width: 2) : null,
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryGold.withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Center(child: centerWidget),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 46,
                color: isCompleted ? AppTheme.statusSuccess : AppTheme.borderSlate,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isCurrent
                          ? AppTheme.primaryDark
                          : (isCompleted ? AppTheme.titleHeading : AppTheme.textMuted),
                    ),
                  ),
                  Text(
                    time,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  void _showReportIssueDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.report_problem_rounded, color: AppTheme.statusError, size: 22),
            SizedBox(width: 8),
            Text('Report Delivery Issue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select the issue encountered:', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            _buildIssueOption(ctx, 'Customer unreachable / wrong phone'),
            _buildIssueOption(ctx, 'Incorrect destination address'),
            _buildIssueOption(ctx, 'Traffic delay / vehicle breakdown'),
            _buildIssueOption(ctx, 'Kitchen packaging damaged'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueOption(BuildContext ctx, String label) {
    return InkWell(
      onTap: () {
        Navigator.pop(ctx);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Issue logged: "$label". Support dispatched.')),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.circle_outlined, size: 14, color: AppTheme.primaryGold),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.titleHeading))),
          ],
        ),
      ),
    );
  }
}
