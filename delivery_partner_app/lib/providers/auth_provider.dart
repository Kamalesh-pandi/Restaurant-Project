import 'package:flutter/material.dart';
import '../models/delivery_partner.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  DeliveryPartner? _partner;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  DeliveryPartner? get partner => _partner;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty && _partner != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> initSession() async {
    _token = await StorageService.getToken();
    _partner = await StorageService.getPartner();
    notifyListeners();
  }

  Future<bool> login(String phone, String pin) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await ApiService.loginWithPin(phone, pin);
    _isLoading = false;

    if (result.success && result.data != null) {
      _token = result.data!['token']?.toString();
      final partnerJson = result.data!['partner'] as Map<String, dynamic>;
      _partner = DeliveryPartner.fromJson(partnerJson);
      notifyListeners();
      return true;
    } else {
      _errorMessage = result.error ?? 'Invalid phone number or PIN';
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String phone,
    String? email,
    required String pinCode,
    required String vehicleType,
    required String vehicleNumber,
    String? outletId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await ApiService.registerPartner(
      name: name,
      phone: phone,
      email: email,
      pinCode: pinCode,
      vehicleType: vehicleType,
      vehicleNumber: vehicleNumber,
      outletId: outletId,
    );

    if (result.success && result.data != null) {
      _token = result.data!['token']?.toString();
      final partnerJson = result.data!['partner'] as Map<String, dynamic>? ?? result.data!;
      _partner = DeliveryPartner.fromJson(partnerJson);
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _isLoading = false;
      _errorMessage = result.error ?? 'Registration failed. Please check your details.';
      notifyListeners();
      return false;
    }
  }

  void updatePartner(DeliveryPartner updated) {
    _partner = updated;
    if (_token != null) {
      StorageService.saveSession(_token!, updated);
    }
    notifyListeners();
  }

  Future<void> logout() async {
    _partner = null;
    _token = null;
    _errorMessage = null;
    await StorageService.clearSession();
    notifyListeners();
  }
}
