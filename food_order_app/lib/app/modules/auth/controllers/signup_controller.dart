import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/storage_service.dart';
import '../../../routes/app_routes.dart';
import '../../../core/utils/snackbars.dart';

class SignUpController extends GetxController {
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final StorageService _storageService = Get.find<StorageService>();

  final RxBool isLoading = false.obs;
  final Rxn<DateTime> selectedBirthday = Rxn<DateTime>();

  // Text Controllers
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final birthdayController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final addressController = TextEditingController();

  Future<void> pickBirthday(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = DateTime(now.year - 18, now.month, now.day);
    final firstDate = DateTime(1920);
    final lastDate = DateTime(now.year - 5);

    final picked = await showDatePicker(
      context: context,
      initialDate: selectedBirthday.value ?? initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select Birthday',
    );

    if (picked != null) {
      selectedBirthday.value = picked;
      birthdayController.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> signUp() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();
    final birthday = birthdayController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    final address = addressController.text.trim();

    // Validations
    if (name.isEmpty) {
      AppSnackbars.showError(title: 'Validation Error', message: 'Please enter your full name.');
      return;
    }

    if (phone.length < 10) {
      AppSnackbars.showError(title: 'Validation Error', message: 'Please enter a valid 10-digit mobile number.');
      return;
    }

    if (email.isNotEmpty && !GetUtils.isEmail(email)) {
      AppSnackbars.showError(title: 'Validation Error', message: 'Please enter a valid email address.');
      return;
    }

    if (password.isEmpty) {
      AppSnackbars.showError(title: 'Validation Error', message: 'Please enter a password.');
      return;
    }

    if (password != confirmPassword) {
      AppSnackbars.showError(title: 'Validation Error', message: 'Passwords do not match.');
      return;
    }

    isLoading.value = true;
    try {
      final user = await _authRepository.signUp(
        name: name,
        phone: phone,
        email: email.isNotEmpty ? email : null,
        birthday: birthday.isNotEmpty ? birthday : null,
        address: address.isNotEmpty ? address : null,
      );

      final token = user.token ?? 'jwt_token_${DateTime.now().millisecondsSinceEpoch}';
      _storageService.saveToken(token);
      _storageService.saveUser(user);

      Get.offAllNamed(AppRoutes.home);
      AppSnackbars.showSuccess(
        title: 'Account Created!',
        message: 'Welcome to Spice Haven, ${user.name}!',
      );
    } catch (e) {
      AppSnackbars.showError(title: 'Sign Up Failed', message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    nameController.clear();
    phoneController.clear();
    emailController.clear();
    birthdayController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    addressController.clear();
    super.onClose();
  }
}
