import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';

enum DialogType { info, success, warning, danger }

class AppDialogs {
  /// General Confirmation Dialog with customizable type, icon, and actions.
  static Future<bool?> confirm({
    String title = 'Are you sure?',
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    DialogType type = DialogType.warning,
    IconData? icon,
    bool isDestructive = false,
    Widget? customContent,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    Color primaryColor;
    List<Color> gradientColors;
    IconData defaultIcon;

    if (isDestructive || type == DialogType.danger) {
      primaryColor = const Color(0xFFE53935);
      gradientColors = const [Color(0xFFFF4B4B), Color(0xFFE53935)];
      defaultIcon = Icons.delete_outline_rounded;
    } else if (type == DialogType.success) {
      primaryColor = const Color(0xFF00C853);
      gradientColors = const [Color(0xFF00E676), Color(0xFF00C853)];
      defaultIcon = Icons.check_circle_outline_rounded;
    } else if (type == DialogType.warning) {
      primaryColor = const Color(0xFFD4AF37);
      gradientColors = const [Color(0xFFFFDF7D), Color(0xFFD4AF37)];
      defaultIcon = Icons.warning_amber_rounded;
    } else {
      primaryColor = AppColors.primary;
      gradientColors = const [Color(0xFF261208), Color(0xFF3F1D0D)];
      defaultIcon = Icons.info_outline_rounded;
    }

    final displayIcon = icon ?? defaultIcon;

    return Get.dialog<bool>(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Decorative Gradient Bar
              Container(
                height: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon Badge with Glowing Ring
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryColor.withOpacity(0.25), width: 2),
                      ),
                      child: Icon(
                        displayIcon,
                        color: primaryColor,
                        size: 34,
                      ),
                    ).animate().scale(
                          begin: const Offset(0.7, 0.7),
                          end: const Offset(1.0, 1.0),
                          duration: 300.ms,
                          curve: Curves.easeOutBack,
                        ),
                    const SizedBox(height: 18),

                    // Title
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2A1508),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Message
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Colors.grey.shade600,
                        height: 1.45,
                      ),
                    ),

                    if (customContent != null) ...[
                      const SizedBox(height: 16),
                      customContent,
                    ],

                    const SizedBox(height: 24),

                    // Buttons Row
                    Row(
                      children: [
                        // Cancel Button
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Get.back(result: false);
                                onCancel?.call();
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  cancelText,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Confirm Button
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Get.back(result: true);
                                onConfirm?.call();
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: gradientColors),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.35),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  confirmText,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
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
      ),
      barrierDismissible: true,
      transitionDuration: const Duration(milliseconds: 220),
    );
  }

  /// Success Dialog (e.g. Table Reserved, Payment Complete)
  static Future<void> success({
    required String title,
    required String message,
    String buttonText = 'Done',
    Widget? extraContent,
    VoidCallback? onDone,
  }) {
    return Get.dialog<void>(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 6,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF00E676), Color(0xFF00C853)],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C853).withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFF00C853).withOpacity(0.3), width: 2),
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF00C853),
                        size: 40,
                      ),
                    ).animate().scale(
                          begin: const Offset(0.6, 0.6),
                          end: const Offset(1.0, 1.0),
                          duration: 350.ms,
                          curve: Curves.easeOutBack,
                        ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2A1508),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Colors.grey.shade600,
                        height: 1.45,
                      ),
                    ),
                    if (extraContent != null) ...[
                      const SizedBox(height: 16),
                      extraContent,
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 3,
                          shadowColor: AppColors.primary.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          Get.back();
                          onDone?.call();
                        },
                        child: Text(
                          buttonText,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  /// Custom Content Dialog (e.g. Rate Order, Payment Simulator Notice)
  static Future<T?> custom<T>({
    required String title,
    IconData icon = Icons.info_outline_rounded,
    Color iconColor = AppColors.primary,
    List<Color>? gradientColors,
    required Widget content,
    List<Widget>? actions,
    bool barrierDismissible = true,
  }) {
    final colors = gradientColors ?? [const Color(0xFF261208), const Color(0xFF3F1D0D)];

    return Get.dialog<T>(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: iconColor.withOpacity(0.25), width: 2),
                      ),
                      child: Icon(icon, color: iconColor, size: 30),
                    ).animate().scale(
                          begin: const Offset(0.7, 0.7),
                          end: const Offset(1.0, 1.0),
                          duration: 300.ms,
                          curve: Curves.easeOutBack,
                        ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2A1508),
                      ),
                    ),
                    const SizedBox(height: 12),
                    content,
                    if (actions != null && actions.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      Row(
                        children: actions
                            .map((act) => Expanded(child: act))
                            .expand((w) => [w, const SizedBox(width: 10)])
                            .toList()
                          ..removeLast(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: barrierDismissible,
    );
  }
}
