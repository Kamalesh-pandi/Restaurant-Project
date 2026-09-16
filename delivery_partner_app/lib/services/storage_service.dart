import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/delivery_partner.dart';

class StorageService {
  static const String _keyToken = 'auth_token';
  static const String _keyPartner = 'partner_data';

  static Future<void> saveSession(String token, DeliveryPartner partner) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyPartner, jsonEncode(partner.toJson()));
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<DeliveryPartner?> getPartner() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyPartner);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return DeliveryPartner.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyPartner);
  }
}
