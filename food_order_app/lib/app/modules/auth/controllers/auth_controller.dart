import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/services/storage_service.dart';
import '../../../routes/app_routes.dart';
import '../../../core/utils/snackbars.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final StorageService _storageService = Get.find<StorageService>();

  final RxBool isLoading = false.obs;

  // Controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> loginWithEmail() async {
    final inputEmail = emailController.text.trim();
    final inputPassword = passwordController.text.trim();

    if (inputEmail.isEmpty || inputPassword.isEmpty) {
      AppSnackbars.showError(title: 'Validation Error', message: 'Please enter both email and password.');
      return;
    }

    isLoading.value = true;
    try {
      UserModel user = await _authRepository.login(
        inputEmail,
        inputPassword,
      );

      // Ensure email is populated if not returned in login response
      if (user.email.isEmpty && inputEmail.contains('@')) {
        user = user.copyWith(email: inputEmail);
      }

      // If user phone is available (or extracted from username), fetch complete customer profile
      // so addresses, order history, loyalty points, and customerId match seamlessly
      if (user.phone.isNotEmpty && Get.isRegistered<CustomerRepository>()) {
        try {
          final customerRepo = Get.find<CustomerRepository>();
          final profile = await customerRepo.getProfileByPhone(user.phone);
          user = user.copyWith(
            id: profile.id.isNotEmpty ? profile.id : user.id,
            name: (profile.name.isNotEmpty && profile.name != 'Gourmet Customer') ? profile.name : user.name,
            email: profile.email.isNotEmpty ? profile.email : user.email,
            loyaltyPoints: profile.loyaltyPoints > 0 ? profile.loyaltyPoints : user.loyaltyPoints,
            address: profile.address != null && profile.address!.isNotEmpty ? profile.address : user.address,
            addresses: profile.addresses.isNotEmpty ? profile.addresses : user.addresses,
          );
        } catch (_) {}
      }

      _storageService.saveToken(user.token ?? 'mock_jwt_token_123');
      _storageService.saveUser(user);

      Get.offAllNamed(AppRoutes.home);
      AppSnackbars.showSuccess(title: 'Welcome Back!', message: 'Logged in successfully as ${user.name}');
    } catch (e) {
      AppSnackbars.showError(title: 'Login Failed', message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailController.clear();
    passwordController.clear();
    super.onClose();
  }
}
