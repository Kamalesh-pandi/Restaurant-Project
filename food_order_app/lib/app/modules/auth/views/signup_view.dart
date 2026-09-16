import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/signup_controller.dart';

class SignUpView extends GetView<SignUpController> {
  const SignUpView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Gradient header background
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF261208), Color(0xFF3F1D0D), Color(0xFF1C0C05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          Column(
            children: [
              // Custom AppBar
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 48, 8, 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                          onPressed: () => Get.back(),
                        ),
                        const Expanded(
                          child: Text(
                            'Create Account',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        // Header card
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFD4AF37), Color(0xFFA07212)],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.person_add_alt_1_rounded, size: 30, color: Colors.white),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Join Spice Haven',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2A1508)),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Unlock loyalty rewards & express delivery',
                                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),
                        ),

                        const SizedBox(height: 20),

                        // Main form
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SectionHeader(label: '1. Personal Details', icon: Icons.person_outline_rounded),
                                const SizedBox(height: 16),

                                _FieldLabel('Full Name *'),
                                const SizedBox(height: 8),
                                _SignupField(
                                  ctrl: controller.nameController,
                                  hint: 'Enter your full name',
                                  icon: Icons.person_outline_rounded,
                                  capitalization: TextCapitalization.words,
                                ),
                                const SizedBox(height: 16),

                                _FieldLabel('Date of Birth'),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () => controller.pickBirthday(context),
                                  child: AbsorbPointer(
                                    child: _SignupField(
                                      ctrl: controller.birthdayController,
                                      hint: 'YYYY-MM-DD',
                                      icon: Icons.cake_outlined,
                                      suffix: Icons.calendar_today_rounded,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),
                                const Divider(),
                                const SizedBox(height: 20),

                                _SectionHeader(label: '2. Contact Information', icon: Icons.contact_phone_rounded),
                                const SizedBox(height: 16),

                                _FieldLabel('Mobile Number *'),
                                const SizedBox(height: 8),
                                _SignupField(
                                  ctrl: controller.phoneController,
                                  hint: '10-digit mobile number',
                                  icon: Icons.phone_iphone_rounded,
                                  keyboardType: TextInputType.phone,
                                  prefix: '+91  ',
                                ),
                                const SizedBox(height: 16),

                                _FieldLabel('Email Address'),
                                const SizedBox(height: 8),
                                _SignupField(
                                  ctrl: controller.emailController,
                                  hint: 'name@example.com',
                                  icon: Icons.alternate_email_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                ),

                                const SizedBox(height: 24),
                                const Divider(),
                                const SizedBox(height: 20),

                                _SectionHeader(label: '3. Security & Address', icon: Icons.security_rounded),
                                const SizedBox(height: 16),

                                _FieldLabel('Password *'),
                                const SizedBox(height: 8),
                                _SignupField(
                                  ctrl: controller.passwordController,
                                  hint: 'Create password (min 6 chars)',
                                  icon: Icons.lock_outline_rounded,
                                  obscure: true,
                                ),
                                const SizedBox(height: 16),

                                _FieldLabel('Confirm Password *'),
                                const SizedBox(height: 8),
                                _SignupField(
                                  ctrl: controller.confirmPasswordController,
                                  hint: 'Re-enter password',
                                  icon: Icons.lock_reset_rounded,
                                  obscure: true,
                                ),
                                const SizedBox(height: 16),

                                _FieldLabel('Delivery Address'),
                                const SizedBox(height: 8),
                                _SignupField(
                                  ctrl: controller.addressController,
                                  hint: 'House/Flat No, Building, Street, Landmark',
                                  icon: Icons.location_on_outlined,
                                  maxLines: 2,
                                ),

                                const SizedBox(height: 32),

                                // Submit Button
                                Obx(
                                  () => SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: GestureDetector(
                                      onTap: controller.isLoading.value ? null : controller.signUp,
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        decoration: BoxDecoration(
                                          gradient: controller.isLoading.value
                                              ? const LinearGradient(colors: [Color(0xFFCCCCCC), Color(0xFFAAAAAA)])
                                              : const LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFA07212)]),
                                          borderRadius: BorderRadius.circular(18),
                                          boxShadow: controller.isLoading.value
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
                                          child: controller.isLoading.value
                                              ? const SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                                )
                                              : const Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                                    SizedBox(width: 10),
                                                    Text(
                                                      'Complete Sign Up',
                                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                                    ),
                                                  ],
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),
                                Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('Already have an account? ',
                                          style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                                      GestureDetector(
                                        onTap: () => Get.back(),
                                        child: const Text(
                                          'Sign In',
                                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 400.ms, delay: 150.ms).slideY(begin: 0.1, end: 0),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionHeader({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF334155)),
    );
  }
}

class _SignupField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final bool obscure;
  final String? prefix;
  final int maxLines;
  final IconData? suffix;
  final TextCapitalization capitalization;

  const _SignupField({
    required this.ctrl,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.obscure = false,
    this.prefix,
    this.maxLines = 1,
    this.suffix,
    this.capitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      obscureText: obscure,
      maxLines: maxLines,
      textCapitalization: capitalization,
      style: const TextStyle(fontSize: 14, color: Color(0xFF2A1508)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixText: prefix,
        prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2A1508), fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
        suffixIcon: suffix != null ? Icon(suffix, color: AppColors.primary, size: 20) : null,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
