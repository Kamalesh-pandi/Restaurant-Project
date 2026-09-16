import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

class AuthProvider {
  final ApiClient _apiClient;

  AuthProvider(this._apiClient);

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _apiClient.post(
      ApiConstants.login,
      data: {
        'email': email,
        'password': password,
      },
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> signUp(Map<String, dynamic> data) async {
    final response = await _apiClient.post(
      ApiConstants.signup,
      data: data,
    );
    return response as Map<String, dynamic>;
  }
}
