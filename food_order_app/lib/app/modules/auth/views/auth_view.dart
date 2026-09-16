import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../controllers/auth_controller.dart';

class AuthView extends GetView<AuthController> {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F3),
      body: Stack(
          children: [
            // Background gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF261208), Color(0xFF3F1D0D), Color(0xFF1C0C05)],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),

            // Top decorative circles
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1.1, 1.1),
                    duration: 3000.ms,
                    curve: Curves.easeInOut,
                  ),
            ),

            // Scrollable content
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          // Hero top section
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
                            child: Column(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/images/logo.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                )
                                    .animate()
                                    .scale(duration: 700.ms, curve: Curves.elasticOut),
                                const SizedBox(height: 16),
                                const Text(
                                  'SPICE HAVEN',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 3.0,
                                  ),
                                ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideY(begin: 0.2, end: 0),
                                const SizedBox(height: 6),
                                Text(
                                  'Good Food Brighter Days • Live Fast Delivery',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
                                const SizedBox(height: 36),
                              ],
                            ),
                          ),

                          // White card body extending completely to the bottom
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(36),
                                  topRight: Radius.circular(36),
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  24,
                                  32,
                                  24,
                                  24 + MediaQuery.of(context).padding.bottom,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Welcome Back!',
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF2A1508),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Sign in with your email and password to continue',
                                      style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                                    ),
                                    const SizedBox(height: 28),

                                    // Email form
                                    _EmailForm(controller: controller),

                                    const SizedBox(height: 28),
                                    Center(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text("New to Spice Haven? ",
                                              style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                                          GestureDetector(
                                            onTap: () => Get.toNamed(AppRoutes.signup),
                                            child: const Text(
                                              'Create Account',
                                              style: TextStyle(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
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
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
    );
  }
}

class _EmailForm extends StatelessWidget {
  final AuthController controller;
  const _EmailForm({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('email'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InputLabel('Email Address'),
        const SizedBox(height: 8),
        _StyledTextField(
          controller: controller.emailController,
          hint: 'name@example.com',
          icon: Icons.alternate_email_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        _InputLabel('Password'),
        const SizedBox(height: 8),
        _StyledTextField(
          controller: controller.passwordController,
          hint: '••••••••',
          icon: Icons.lock_outline_rounded,
          obscure: true,
        ),
        const SizedBox(height: 32),
        Obx(() => _GradientButton(
              label: 'Sign In to Gourmet',
              icon: Icons.login_rounded,
              isLoading: controller.isLoading.value,
              onTap: controller.loginWithEmail,
            )),
      ],
    );
  }
}

class _InputLabel extends StatelessWidget {
  final String text;
  const _InputLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final bool obscure;
  final String? prefix;
  final int? maxLength;
  final bool centered;
  final bool large;

  const _StyledTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.obscure = false,
    this.prefix,
    this.maxLength,
    this.centered = false,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      maxLength: maxLength,
      textAlign: centered ? TextAlign.center : TextAlign.start,
      style: TextStyle(
        fontSize: large ? 24 : 14,
        fontWeight: large ? FontWeight.bold : FontWeight.normal,
        letterSpacing: large ? 10 : 0,
        color: const Color(0xFF2A1508),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontSize: large ? 20 : 14,
          letterSpacing: large ? 8 : 0,
        ),
        prefixText: prefix,
        prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2A1508)),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
        counterText: '',
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onTap;

  const _GradientButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: GestureDetector(
        onTap: isLoading ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: isLoading
                ? const LinearGradient(colors: [Color(0xFFCCCCCC), Color(0xFFAAAAAA)])
                : const LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFA07212)]),
            borderRadius: BorderRadius.circular(18),
            boxShadow: isLoading
                ? []
                : [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.45),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        label,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).shimmer(delay: 1000.ms, duration: 1000.ms, color: Colors.white.withOpacity(0.3));
  }
}
