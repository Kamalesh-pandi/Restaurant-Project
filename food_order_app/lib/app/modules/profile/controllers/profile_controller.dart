import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/customer_address_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/services/storage_service.dart';
import '../../../routes/app_routes.dart';
import '../../../core/utils/snackbars.dart';
import '../../../core/utils/app_dialogs.dart';
import '../../cart/controllers/cart_controller.dart';

class ProfileController extends GetxController {
  final CustomerRepository _customerRepository = Get.find<CustomerRepository>();
  final OrderRepository _orderRepository = Get.find<OrderRepository>();
  final StorageService _storageService = Get.find<StorageService>();

  final Rxn<UserModel> userProfile = Rxn<UserModel>();
  final RxBool isDarkMode = false.obs;
  final RxList<OrderModel> pastOrders = <OrderModel>[].obs;
  final RxBool isLoading = false.obs;

  final RxList<CustomerAddressModel> customerAddresses = <CustomerAddressModel>[].obs;
  final RxList<String> savedAddresses = <String>[].obs;
  final RxString selectedAddress = ''.obs;
  final RxnString selectedAddressId = RxnString();

  @override
  void onInit() {
    super.onInit();
    isDarkMode.value = _storageService.isDarkMode;
    loadUserData();
  }

  void _saveAddressesToStorage() {
    final list = customerAddresses.map((a) => a.toJson()).toList();
    _storageService.saveCustomerAddressesJson(list);
  }

  Future<void> loadUserData() async {
    final current = _storageService.user;
    savedAddresses.clear();
    customerAddresses.clear();

    final deletedIds = _storageService.deletedAddressIds;
    final deletedStrings = _storageService.deletedAddressStrings;

    // 1. Load local persistent customer addresses
    final cachedJson = _storageService.savedCustomerAddressesJson;
    if (cachedJson.isNotEmpty) {
      final cachedList = cachedJson.map((e) => CustomerAddressModel.fromJson(e)).where((a) {
        if (a.addressId != null && deletedIds.contains(a.addressId)) return false;
        if (deletedStrings.contains(a.fullAddress.trim())) return false;
        return true;
      }).toList();
      customerAddresses.assignAll(cachedList);
      for (var a in cachedList) {
        _addUniqueAddress(a.fullAddress);
      }
    }

    if (current != null) {
      userProfile.value = current;
      if (!deletedStrings.contains(current.address?.trim())) {
        _syncSavedAddresses(current.address);
      }

      try {
        isLoading.value = true;
        if (current.phone.isNotEmpty) {
          final addrs = await _customerRepository.getAddresses(current.phone, customerId: current.id);
          final filteredAddrs = addrs.where((a) {
            if (a.addressId != null && deletedIds.contains(a.addressId)) return false;
            if (deletedStrings.contains(a.fullAddress.trim())) return false;
            return true;
          }).toList();

          if (filteredAddrs.isNotEmpty) {
            customerAddresses.assignAll(filteredAddrs);
            _saveAddressesToStorage();

            final def = filteredAddrs.firstWhereOrNull((a) => a.isDefault) ?? filteredAddrs.first;
            selectedAddressId.value = def.addressId;
            _syncSavedAddresses(def.fullAddress);
            for (var a in filteredAddrs) {
              _addUniqueAddress(a.fullAddress);
            }
          }
        }
      } catch (_) {}

      try {
        if (current.phone.isNotEmpty) {
          final updated = await _customerRepository.getProfileByPhone(current.phone);
          if (updated.id.isNotEmpty) {
            userProfile.value = updated;
            _storageService.saveUser(updated);
            if (!deletedStrings.contains(updated.address?.trim())) {
              _syncSavedAddresses(updated.address);
            }
          }
        }
      } catch (_) {}

      try {
        if (current.phone.isNotEmpty) {
          final history = await _orderRepository.getOrderHistory(current.phone);
          final Map<String, OrderModel> uniqueOrders = {};
          for (var order in history) {
            final key = (order.id != null && order.id!.isNotEmpty)
                ? order.id!
                : '${order.grandTotal}_${order.createdAt.millisecondsSinceEpoch}';
            if (!uniqueOrders.containsKey(key)) {
              uniqueOrders[key] = order;
            }
          }

          final uniqueList = uniqueOrders.values.toList();
          pastOrders.assignAll(uniqueList);

          for (var order in uniqueList) {
            final delAddr = order.deliveryAddress?.trim();
            if (delAddr != null && delAddr.isNotEmpty && !deletedStrings.contains(delAddr)) {
              _addUniqueAddress(delAddr);
            }
          }
        } else {
          pastOrders.clear();
        }
      } catch (_) {
        pastOrders.clear();
      } finally {
        isLoading.value = false;
      }
    } else {
      userProfile.value = UserModel(
        id: '',
        name: 'Guest Customer',
        email: '',
        phone: '',
        loyaltyPoints: 0,
        address: '',
      );
    }
  }

  void _syncSavedAddresses(String? dbAddress) {
    if (dbAddress != null && dbAddress.trim().isNotEmpty) {
      final trimmed = dbAddress.trim();
      if (!_storageService.deletedAddressStrings.contains(trimmed)) {
        _addUniqueAddress(trimmed);
        selectedAddress.value = trimmed;
      }
    }
  }

  void _addUniqueAddress(String addr) {
    final trimmed = addr.trim();
    if (trimmed.isEmpty) return;
    if (_storageService.deletedAddressStrings.contains(trimmed)) return;
    if (!savedAddresses.contains(trimmed)) {
      savedAddresses.add(trimmed);
    }
  }

  Future<void> addNewCustomerAddress({
    required String label,
    required String houseNo,
    required String street,
    required String landmark,
    required String city,
    required String pincode,
  }) async {
    final phone = userProfile.value?.phone ?? _storageService.user?.phone ?? '';
    final customerId = userProfile.value?.id ?? _storageService.user?.id;
    if (phone.isEmpty) return;

    List<String> parts = [houseNo, street, landmark, city, pincode].where((p) => p.trim().isNotEmpty).toList();
    String fullAddr = parts.join(', ');

    final newAddr = CustomerAddressModel(
      addressId: 'ADDR-${DateTime.now().millisecondsSinceEpoch}',
      label: label,
      houseNo: houseNo,
      street: street,
      landmark: landmark,
      city: city,
      pincode: pincode,
      fullAddress: fullAddr,
      isDefault: customerAddresses.isEmpty,
    );

    final created = await _customerRepository.addAddress(phone, newAddr, customerId: customerId);
    final target = created ?? newAddr;

    customerAddresses.removeWhere((a) => a.fullAddress == target.fullAddress);
    customerAddresses.add(target);
    _addUniqueAddress(target.fullAddress);
    _saveAddressesToStorage();

    if (target.isDefault || customerAddresses.length == 1) {
      setPrimaryCustomerAddress(target);
    }

    AppSnackbars.showSuccess(
      title: 'Address Saved',
      message: '${target.label} address saved successfully.',
    );
  }

  Future<void> setPrimaryCustomerAddress(CustomerAddressModel addr) async {
    final phone = userProfile.value?.phone ?? _storageService.user?.phone ?? '';
    final customerId = userProfile.value?.id ?? _storageService.user?.id;

    selectedAddressId.value = addr.addressId;
    selectedAddress.value = addr.fullAddress;
    _addUniqueAddress(addr.fullAddress);

    if (Get.isRegistered<CartController>()) {
      final cart = Get.find<CartController>();
      cart.deliveryAddress.value = addr.fullAddress;
      cart.selectedAddressId.value = addr.addressId;
    }

    if (addr.addressId != null && phone.isNotEmpty) {
      await _customerRepository.setDefaultAddress(addr.addressId!, phone, customerId: customerId);
    }

    customerAddresses.assignAll(customerAddresses.map((a) {
      return a.copyWith(isDefault: a.addressId == addr.addressId);
    }).toList());
    _saveAddressesToStorage();

    if (userProfile.value != null) {
      final updated = userProfile.value!.copyWith(address: addr.fullAddress);
      userProfile.value = updated;
      _storageService.saveUser(updated);
    }
  }

  Future<void> deleteCustomerAddress(CustomerAddressModel addr) async {
    if (addr.addressId != null) {
      await _customerRepository.deleteAddress(addr.addressId!);
      await _storageService.addDeletedAddressId(addr.addressId!);
    }
    await _storageService.addDeletedAddressString(addr.fullAddress);

    customerAddresses.removeWhere((a) => a.addressId == addr.addressId || a.fullAddress == addr.fullAddress);
    savedAddresses.remove(addr.fullAddress);
    _saveAddressesToStorage();

    if (selectedAddressId.value == addr.addressId || selectedAddress.value == addr.fullAddress) {
      if (customerAddresses.isNotEmpty) {
        setPrimaryCustomerAddress(customerAddresses.first);
      } else if (savedAddresses.isNotEmpty) {
        setPrimaryAddress(savedAddresses.first);
      } else {
        selectedAddress.value = '';
        selectedAddressId.value = null;
        if (userProfile.value != null) {
          final updated = userProfile.value!.copyWith(address: '');
          userProfile.value = updated;
          _storageService.saveUser(updated);
        }
      }
    }

    AppSnackbars.showSuccess(
      title: 'Address Removed',
      message: '${addr.label} address deleted from profile.',
    );
  }

  Future<void> deleteSavedAddressString(String addr) async {
    await _storageService.addDeletedAddressString(addr);
    savedAddresses.remove(addr);
    customerAddresses.removeWhere((a) => a.fullAddress == addr);
    _saveAddressesToStorage();

    if (selectedAddress.value == addr) {
      if (customerAddresses.isNotEmpty) {
        setPrimaryCustomerAddress(customerAddresses.first);
      } else if (savedAddresses.isNotEmpty) {
        setPrimaryAddress(savedAddresses.first);
      } else {
        selectedAddress.value = '';
        selectedAddressId.value = null;
        if (userProfile.value != null) {
          final updated = userProfile.value!.copyWith(address: '');
          userProfile.value = updated;
          _storageService.saveUser(updated);
        }
      }
    }

    AppSnackbars.showSuccess(
      title: 'Address Removed',
      message: 'Address deleted from profile.',
    );
  }

  void confirmDeleteCustomerAddress(CustomerAddressModel addr) {
    AppDialogs.confirm(
      title: 'Delete Address?',
      message: 'Are you sure you want to delete "${addr.label}" address?\n${addr.fullAddress}',
      confirmText: 'Delete',
      cancelText: 'Keep',
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
      onConfirm: () => deleteCustomerAddress(addr),
    );
  }

  void confirmDeleteSavedAddress(String addr) {
    AppDialogs.confirm(
      title: 'Delete Address?',
      message: 'Are you sure you want to delete this saved address?\n"$addr"',
      confirmText: 'Delete',
      cancelText: 'Keep',
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
      onConfirm: () => deleteSavedAddressString(addr),
    );
  }

  void updateProfile({
    required String name,
    required String email,
    required String phone,
    required String address,
  }) async {
    if (userProfile.value == null) return;
    final trimmedAddr = address.trim();
    final updated = userProfile.value!.copyWith(
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
      address: trimmedAddr,
    );
    userProfile.value = updated;
    _syncSavedAddresses(trimmedAddr);
    _storageService.saveUser(updated);

    try {
      final backendUpdated = await _customerRepository.updateProfile(updated);
      userProfile.value = backendUpdated;
      _storageService.saveUser(backendUpdated);
      _syncSavedAddresses(backendUpdated.address);
    } catch (_) {}

    AppSnackbars.showSuccess(
      title: 'Profile Updated',
      message: 'Your account details have been saved successfully.',
    );
  }

  void addSavedAddress(String newAddr) {
    final trimmed = newAddr.trim();
    if (trimmed.isEmpty) return;
    _addUniqueAddress(trimmed);
    setPrimaryAddress(trimmed);
  }

  void setPrimaryAddress(String addr) {
    final trimmed = addr.trim();
    selectedAddress.value = trimmed;
    _addUniqueAddress(trimmed);

    if (Get.isRegistered<CartController>()) {
      final cart = Get.find<CartController>();
      cart.deliveryAddress.value = trimmed;
    }

    if (userProfile.value != null) {
      final updated = userProfile.value!.copyWith(address: trimmed);
      userProfile.value = updated;
      _storageService.saveUser(updated);
    }
    AppSnackbars.showSuccess(
      title: 'Address Updated',
      message: 'Set as your default delivery address.',
    );
  }

  void redeemReward(int ptsCost, String rewardTitle) {
    final currentPts = userProfile.value?.loyaltyPoints ?? 0;
    if (currentPts < ptsCost) {
      AppSnackbars.showError(
        title: 'Insufficient Points',
        message: 'You need $ptsCost loyalty points to redeem $rewardTitle.',
      );
      return;
    }

    final updatedPts = currentPts - ptsCost;
    final updatedUser = userProfile.value!.copyWith(loyaltyPoints: updatedPts);
    userProfile.value = updatedUser;
    _storageService.saveUser(updatedUser);

    AppSnackbars.showSuccess(
      title: 'Reward Unlocked! 🎉',
      message: 'You redeemed $rewardTitle! Applied to your next order.',
    );
  }

  void reorder(OrderModel order) {
    if (Get.isRegistered<CartController>()) {
      final cartController = Get.find<CartController>();
      for (var item in order.items) {
        cartController.addToCart(item.item, quantity: item.quantity, selectedModifiers: item.selectedModifiers);
      }
      Get.toNamed(AppRoutes.cart);
      AppSnackbars.showSuccess(
        title: 'Items Added',
        message: 'All items from Order #${order.id} added to your cart!',
      );
    } else {
      Get.toNamed(AppRoutes.cart);
    }
  }

  void toggleTheme(bool value) {
    isDarkMode.value = value;
    _storageService.saveDarkMode(value);
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
  }

  void submitFeedback(String orderId, double rating, String comments) async {
    await _customerRepository.submitFeedback(orderId, rating, comments);
    AppSnackbars.showSuccess(
      title: 'Feedback Recorded ⭐',
      message: 'Thank you for rating your Spice Haven experience!',
    );
  }

  void confirmLogout() {
    AppDialogs.confirm(
      title: 'Sign Out Account?',
      message: 'Are you sure you want to sign out of your Spice Haven account?',
      confirmText: 'Sign Out',
      cancelText: 'Stay Signed In',
      isDestructive: true,
      icon: Icons.logout_rounded,
      onConfirm: () => logout(),
    );
  }

  void logout() async {
    await _storageService.logout();
    Get.offAllNamed(AppRoutes.auth);
  }
}
