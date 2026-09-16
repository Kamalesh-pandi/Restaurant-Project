import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../core/constants/storage_keys.dart';
import '../models/user_model.dart';

class StorageService extends GetxService {
  late final GetStorage _box;

  Future<StorageService> init() async {
    await GetStorage.init();
    _box = GetStorage();
    return this;
  }

  // Token Management
  String? get token => _box.read(StorageKeys.token);
  Future<void> saveToken(String token) async => await _box.write(StorageKeys.token, token);
  Future<void> clearToken() async => await _box.remove(StorageKeys.token);

  // User Profile
  UserModel? get user {
    final data = _box.read(StorageKeys.userProfile);
    if (data != null && data is Map<String, dynamic>) {
      return UserModel.fromJson(data);
    }
    return null;
  }

  Future<void> saveUser(UserModel user) async {
    await _box.write(StorageKeys.userProfile, user.toJson());
  }

  Future<void> clearUser() async {
    await _box.remove(StorageKeys.userProfile);
  }

  // Dark Mode Preference
  bool get isDarkMode => _box.read(StorageKeys.isDarkMode) ?? false;
  Future<void> saveDarkMode(bool isDark) async => await _box.write(StorageKeys.isDarkMode, isDark);

  // Selected Outlet / Delivery Location
  String? get selectedOutlet => _box.read(StorageKeys.selectedOutlet);
  Future<void> saveSelectedOutlet(String outlet) async => await _box.write(StorageKeys.selectedOutlet, outlet);

  // Active Order Tracking
  String? get activeOrderId => _box.read(StorageKeys.activeOrderId);
  Future<void> saveActiveOrderId(String orderId) async => await _box.write(StorageKeys.activeOrderId, orderId);
  Future<void> clearActiveOrderId() async => await _box.remove(StorageKeys.activeOrderId);

  List<String> get activeOrderIds {
    final list = _box.read('active_order_ids');
    if (list is List) return list.map((e) => e.toString()).toList();
    if (activeOrderId != null && activeOrderId!.isNotEmpty) return [activeOrderId!];
    return [];
  }

  Future<void> addActiveOrderId(String orderId) async {
    final list = List<String>.from(activeOrderIds);
    if (!list.contains(orderId)) {
      list.insert(0, orderId);
      await _box.write('active_order_ids', list);
    }
    await saveActiveOrderId(orderId);
  }

  Future<void> removeActiveOrderId(String orderId) async {
    final list = List<String>.from(activeOrderIds);
    list.remove(orderId);
    await _box.write('active_order_ids', list);
    if (activeOrderId == orderId) {
      if (list.isNotEmpty) {
        await saveActiveOrderId(list.first);
      } else {
        await clearActiveOrderId();
      }
    }
  }

  // Saved Customer Addresses Persistence
  List<Map<String, dynamic>> get savedCustomerAddressesJson {
    final list = _box.read('saved_customer_addresses_json');
    if (list is List) {
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  Future<void> saveCustomerAddressesJson(List<Map<String, dynamic>> list) async {
    await _box.write('saved_customer_addresses_json', list);
  }

  List<String> get deletedAddressIds {
    final list = _box.read('deleted_address_ids');
    if (list is List) return list.map((e) => e.toString()).toList();
    return [];
  }

  Future<void> addDeletedAddressId(String id) async {
    final list = deletedAddressIds;
    if (!list.contains(id)) {
      list.add(id);
      await _box.write('deleted_address_ids', list);
    }
  }

  List<String> get deletedAddressStrings {
    final list = _box.read('deleted_address_strings');
    if (list is List) return list.map((e) => e.toString()).toList();
    return [];
  }

  Future<void> addDeletedAddressString(String addrStr) async {
    final trimmed = addrStr.trim();
    if (trimmed.isEmpty) return;
    final list = deletedAddressStrings;
    if (!list.contains(trimmed)) {
      list.add(trimmed);
      await _box.write('deleted_address_strings', list);
    }
  }

  // Clean all session data
  Future<void> logout() async {
    await clearToken();
    await clearUser();
    await _box.remove(StorageKeys.savedCart);
    await _box.remove('saved_customer_addresses_json');
    await _box.remove('deleted_address_ids');
    await _box.remove('deleted_address_strings');
    await clearActiveOrderId();
  }
}
