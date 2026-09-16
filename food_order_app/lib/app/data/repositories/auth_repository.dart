import '../models/user_model.dart';
import '../providers/auth_provider.dart';

class AuthRepository {
  final AuthProvider _authProvider;

  AuthRepository(this._authProvider);

  Future<UserModel> login(String email, String password) async {
    final data = await _authProvider.login(email, password);
    return UserModel.fromJson(data);
  }

  Future<UserModel> signUp({
    required String name,
    required String phone,
    String? email,
    String? birthday,
    String? address,
  }) async {
    final payload = {
      'name': name,
      'phone': phone,
      if (email != null && email.isNotEmpty) 'email': email,
      if (birthday != null && birthday.isNotEmpty) 'birthday': birthday,
      if (address != null && address.isNotEmpty) 'address': address,
    };
    final data = await _authProvider.signUp(payload);
    return UserModel.fromJson(data);
  }
}
