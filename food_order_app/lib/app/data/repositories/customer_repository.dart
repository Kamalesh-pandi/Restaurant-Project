import '../models/customer_address_model.dart';
import '../models/user_model.dart';
import '../providers/customer_provider.dart';

class CustomerRepository {
  final CustomerProvider _customerProvider;

  CustomerRepository(this._customerProvider);

  Future<UserModel> getProfile(String customerId) async {
    final res = await _customerProvider.getProfile(customerId);
    return UserModel.fromJson(res);
  }

  Future<UserModel> getProfileByPhone(String phone) async {
    final res = await _customerProvider.getProfileByPhone(phone);
    return UserModel.fromJson(res);
  }

  Future<UserModel> updateProfile(UserModel user) async {
    try {
      final res = await _customerProvider.updateProfile(user.toJson());
      return UserModel.fromJson(res);
    } catch (_) {
      return user;
    }
  }

  Future<bool> submitFeedback(String orderId, double rating, String comments) async {
    try {
      await _customerProvider.submitFeedback({
        'visitId': orderId,
        'orderId': orderId,
        'rating': rating.toInt(),
        'comment': comments,
        'comments': comments,
      });
      return true;
    } catch (_) {
      return true;
    }
  }

  // Address Repository Methods
  Future<List<CustomerAddressModel>> getAddresses(String phone, {String? customerId}) async {
    try {
      final rawList = await _customerProvider.getAddresses(phone, customerId: customerId);
      return rawList.map((item) => CustomerAddressModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<CustomerAddressModel?> addAddress(String phone, CustomerAddressModel address, {String? customerId}) async {
    try {
      final res = await _customerProvider.addAddress(phone, address.toJson(), customerId: customerId);
      return CustomerAddressModel.fromJson(res);
    } catch (_) {
      return null;
    }
  }

  Future<CustomerAddressModel?> updateAddress(String addressId, CustomerAddressModel address) async {
    try {
      final res = await _customerProvider.updateAddress(addressId, address.toJson());
      return CustomerAddressModel.fromJson(res);
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteAddress(String addressId) async {
    try {
      await _customerProvider.deleteAddress(addressId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setDefaultAddress(String addressId, String phone, {String? customerId}) async {
    try {
      await _customerProvider.setDefaultAddress(addressId, phone, customerId: customerId);
      return true;
    } catch (_) {
      return false;
    }
  }
}
