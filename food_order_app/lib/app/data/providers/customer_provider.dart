import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

class CustomerProvider {
  final ApiClient _apiClient;

  CustomerProvider(this._apiClient);

  Future<Map<String, dynamic>> getProfile(String customerId) async {
    final response = await _apiClient.get(ApiConstants.customerProfile(customerId));
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getProfileByPhone(String phone) async {
    final response = await _apiClient.get(ApiConstants.customerProfileByPhone(phone));
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await _apiClient.post(
      ApiConstants.updateProfile,
      data: data,
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> submitFeedback(Map<String, dynamic> feedbackData) async {
    final response = await _apiClient.post(
      ApiConstants.customerFeedback,
      data: feedbackData,
    );
    return response as Map<String, dynamic>;
  }

  // Address CRUD Endpoints
  Future<List<dynamic>> getAddresses(String phone, {String? customerId}) async {
    final response = await _apiClient.get(ApiConstants.customerAddresses(phone, customerId: customerId));
    return response as List<dynamic>;
  }

  Future<Map<String, dynamic>> addAddress(String phone, Map<String, dynamic> data, {String? customerId}) async {
    final response = await _apiClient.post(
      ApiConstants.customerAddresses(phone, customerId: customerId),
      data: data,
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateAddress(String addressId, Map<String, dynamic> data) async {
    final response = await _apiClient.put(
      ApiConstants.customerAddressDetail(addressId),
      data: data,
    );
    return response as Map<String, dynamic>;
  }

  Future<void> deleteAddress(String addressId) async {
    await _apiClient.delete(ApiConstants.customerAddressDetail(addressId));
  }

  Future<Map<String, dynamic>> setDefaultAddress(String addressId, String phone, {String? customerId}) async {
    final response = await _apiClient.patch(
      ApiConstants.setDefaultAddress(addressId, phone, customerId: customerId),
    );
    return response as Map<String, dynamic>;
  }
}
