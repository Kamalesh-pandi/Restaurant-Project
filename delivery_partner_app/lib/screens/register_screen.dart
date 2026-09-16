import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/duty_provider.dart';
import '../widgets/glass_card.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _vehicleNumberController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  String _selectedVehicleType = 'BIKE';
  bool _obscurePin = true;
  bool _obscureConfirmPin = true;

  final List<Map<String, dynamic>> _vehicleTypes = [
    {'type': 'BIKE', 'label': 'Motorcycle', 'icon': Icons.two_wheeler_rounded},
    {'type': 'SCOOTER', 'label': 'Scooter', 'icon': Icons.moped_rounded},
    {'type': 'EV', 'label': 'Electric EV', 'icon': Icons.electric_scooter_rounded},
    {'type': 'BICYCLE', 'label': 'Bicycle', 'icon': Icons.pedal_bike_rounded},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _vehicleNumberController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    String phone = _phoneController.text.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    if (phone.startsWith('+91')) {
      phone = phone.substring(3);
    } else if (phone.startsWith('91') && phone.length == 12) {
      phone = phone.substring(2);
    } else if (phone.startsWith('0') && phone.length == 11) {
      phone = phone.substring(1);
    }
    final email = _emailController.text.trim();
    final vehicleNumber = _vehicleNumberController.text.trim().toUpperCase();
    final pin = _pinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    if (pin != confirmPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PIN codes do not match. Please re-enter.'),
          backgroundColor: AppTheme.rose,
        ),
      );
      return;
    }

    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final dutyProv = Provider.of<DutyProvider>(context, listen: false);

    final success = await authProv.register(
      name: name,
      phone: phone,
      email: email.isNotEmpty ? email : null,
      pinCode: pin,
      vehicleType: _selectedVehicleType,
      vehicleNumber: vehicleNumber,
    );

    if (success && mounted) {
      dutyProv.initStatus(authProv.partner);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Welcome to Spice Haven! Registration successful.'),
          backgroundColor: AppTheme.statusSuccess,
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else if (mounted) {
      final error = authProv.errorMessage ?? 'Registration failed. Please check your details.';
      final isAlreadyRegistered = error.toLowerCase().contains('already registered') || error.toLowerCase().contains('already exists');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppTheme.rose,
          duration: const Duration(seconds: 4),
          action: isAlreadyRegistered
              ? SnackBarAction(
                  label: 'SIGN IN',
                  textColor: Colors.white,
                  onPressed: () => Navigator.of(context).pop(),
                )
              : null,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProv = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      body: Stack(
        children: [
          // Background Espresso Gradient (Dark Roast Espresso system matching food_order_app)
          Container(
            height: MediaQuery.of(context).size.height * 0.36,
            decoration: const BoxDecoration(
              gradient: AppTheme.luxuryHeaderGradient,
            ),
          ),

          // Top Ambient Decorative Circles
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            top: 80,
            left: -30,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),

          // Scrollable Content
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                children: [
                  // Header Brand Badge & Logo
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.gold, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.person_add_alt_1_rounded,
                                size: 40,
                                color: AppTheme.primaryGold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Title
                        const Text(
                          'SPICE HAVEN',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.lightOnDarkTitle,
                            letterSpacing: 2.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'GOOD FOOD BRIGHTER DAYS',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.goldLight,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Delivery Partner Fleet Registration',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.85),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Rounded Form Card Body extending to bottom
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 520),
                    decoration: const BoxDecoration(
                      color: AppTheme.appBackground,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 16,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.fromLTRB(
                      24,
                      28,
                      24,
                      24 + MediaQuery.of(context).padding.bottom,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Partner Registration',
                            style: TextStyle(
                              color: AppTheme.titleHeading,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Complete your details to join the logistics network',
                            style: TextStyle(color: AppTheme.bodySecondary, fontSize: 13),
                          ),
                          const SizedBox(height: 20),

                          // Main Glass Form Card
                          GlassCard(
                            padding: const EdgeInsets.all(22),
                            backgroundColor: Colors.white,
                            borderColor: AppTheme.borderNeutral,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                          // Section: Personal Details
                          const Row(
                            children: [
                              Icon(Icons.badge_rounded, size: 16, color: AppTheme.emeraldNeon),
                              SizedBox(width: 8),
                              Text(
                                'Personal Details',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Full Name
                          TextFormField(
                            controller: _nameController,
                            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              hintText: 'e.g. John Doe',
                              prefixIcon: Icon(Icons.person_outline_rounded, color: AppTheme.emerald),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter your full name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Mobile Phone
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                            decoration: const InputDecoration(
                              labelText: 'Mobile Phone',
                              hintText: '10-digit mobile number',
                              prefixIcon: Icon(Icons.phone_iphone_rounded, color: AppTheme.emerald),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter your mobile phone';
                              }
                              final cleaned = val.replaceAll(RegExp(r'\D'), '');
                              if (cleaned.length < 10) {
                                return 'Please enter a valid 10-digit phone number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Email (Optional)
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                            decoration: const InputDecoration(
                              labelText: 'Email Address (Optional)',
                              hintText: 'john@example.com',
                              prefixIcon: Icon(Icons.email_outlined, color: AppTheme.emerald),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Section: Vehicle Info
                          const Row(
                            children: [
                              Icon(Icons.moped_rounded, size: 16, color: AppTheme.amber),
                              SizedBox(width: 8),
                              Text(
                                'Vehicle Information',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Vehicle Type Selector Chips
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _vehicleTypes.map((vt) {
                              final isSelected = _selectedVehicleType == vt['type'];
                              return ChoiceChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      vt['icon'] as IconData,
                                      size: 16,
                                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      vt['label'] as String,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                selected: isSelected,
                                selectedColor: AppTheme.emerald,
                                backgroundColor: AppTheme.surfaceHighlight,
                                side: BorderSide(
                                  color: isSelected ? AppTheme.emeraldNeon : AppTheme.borderSlate,
                                ),
                                onSelected: (sel) {
                                  if (sel) {
                                    setState(() => _selectedVehicleType = vt['type'] as String);
                                  }
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),

                          // Vehicle Plate Number
                          TextFormField(
                            controller: _vehicleNumberController,
                            textCapitalization: TextCapitalization.characters,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Vehicle Plate Number',
                              hintText: 'e.g. KA-01-AB-1234',
                              prefixIcon: Icon(Icons.confirmation_number_outlined, color: AppTheme.amber),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter vehicle registration number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Section: Security PIN
                          const Row(
                            children: [
                              Icon(Icons.shield_rounded, size: 16, color: AppTheme.emeraldNeon),
                              SizedBox(width: 8),
                              Text(
                                'Security PIN',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // 4-Digit Access PIN
                          TextFormField(
                            controller: _pinController,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            obscureText: _obscurePin,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 8,
                              fontSize: 18,
                            ),
                            decoration: InputDecoration(
                              labelText: '4-Digit Login PIN',
                              hintText: '••••',
                              prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.emerald),
                              counterText: '',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePin ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  color: AppTheme.textSecondary,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _obscurePin = !_obscurePin),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().length != 4) {
                                return 'PIN must be exactly 4 digits';
                              }
                              if (int.tryParse(val.trim()) == null) {
                                return 'PIN must contain numbers only';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Confirm 4-Digit PIN
                          TextFormField(
                            controller: _confirmPinController,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            obscureText: _obscureConfirmPin,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 8,
                              fontSize: 18,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Confirm 4-Digit PIN',
                              hintText: '••••',
                              prefixIcon: const Icon(Icons.lock_reset_rounded, color: AppTheme.emerald),
                              counterText: '',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPin ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  color: AppTheme.textSecondary,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _obscureConfirmPin = !_obscureConfirmPin),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().length != 4) {
                                return 'Confirm PIN must be 4 digits';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Register Button with Imperial Action Gradient
                          Container(
                            decoration: BoxDecoration(
                              gradient: AppTheme.imperialActionGradient,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryGold.withOpacity(0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: authProv.isLoading ? null : _handleRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: authProv.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.how_to_reg_rounded, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'REGISTER & JOIN FLEET',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Already have an account? Sign In
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already a delivery partner? ',
                          style: TextStyle(color: AppTheme.bodySecondary, fontSize: 13),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                          ),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              color: AppTheme.primaryGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ],
),
);
  }
}
