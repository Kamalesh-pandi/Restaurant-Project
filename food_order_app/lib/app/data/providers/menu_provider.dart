import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

class MenuProvider {
  final ApiClient _apiClient;

  MenuProvider(this._apiClient);

  Future<List<dynamic>> getCategories() async {
    final response = await _apiClient.get(ApiConstants.categories);
    return response is List ? response : (response['data'] ?? []);
  }

  Future<List<dynamic>> getMenuItems() async {
    final response = await _apiClient.get(ApiConstants.menuItems);
    return response is List ? response : (response['data'] ?? []);
  }

  Future<List<dynamic>> getMenuItemsByCategory(String categoryId) async {
    final response = await _apiClient.get('${ApiConstants.menuItemsByCategory}$categoryId');
    return response is List ? response : (response['data'] ?? []);
  }

  Future<List<dynamic>> getSpecials() async {
    final response = await _apiClient.get(ApiConstants.specials);
    return response is List ? response : (response['data'] ?? []);
  }

  Future<List<dynamic>> getModifierGroups(String itemId) async {
    final response = await _apiClient.get(ApiConstants.itemModifiers(itemId));
    return response is List ? response : (response['data'] ?? []);
  }
}
