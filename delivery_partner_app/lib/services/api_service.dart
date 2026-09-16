import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/delivery_partner.dart';
import '../models/delivery_partner_stats.dart';
import '../models/delivery_assignment.dart';
import '../models/order_details.dart';
import 'storage_service.dart';

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;

  ApiResponse({required this.success, this.data, this.error});
}

class ApiService {
  static Future<Map<String, String>> _headers() async {
    final token = await StorageService.getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // 1. PIN Login
  static Future<ApiResponse<Map<String, dynamic>>> loginWithPin(String phone, String pinCode) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/delivery-partner/login-pin');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone.trim(),
          'pinCode': pinCode.trim(),
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['token']?.toString() ?? '';
        final partnerJson = data['partner'] as Map<String, dynamic>;
        final partner = DeliveryPartner.fromJson(partnerJson);
        await StorageService.saveSession(token, partner);
        return ApiResponse(success: true, data: data);
      } else {
        String errorMsg = 'Login failed (${response.statusCode})';
        try {
          final errBody = jsonDecode(response.body);
          if (errBody is Map && errBody['message'] != null) {
            errorMsg = errBody['message'].toString();
          }
        } catch (_) {}
        return ApiResponse(success: false, error: errorMsg);
      }
    } catch (e) {
      return ApiResponse(success: false, error: 'Connection error: Could not reach server at ${ApiConfig.baseUrl}');
    }
  }

  // 1b. Partner Registration
  static Future<ApiResponse<Map<String, dynamic>>> registerPartner({
    required String name,
    required String phone,
    String? email,
    required String pinCode,
    required String vehicleType,
    required String vehicleNumber,
    String? outletId,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/delivery-partner/register');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name.trim(),
          'phone': phone.trim(),
          if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
          'pinCode': pinCode.trim(),
          'vehicleType': vehicleType.trim(),
          'vehicleNumber': vehicleNumber.trim(),
          if (outletId != null && outletId.isNotEmpty) 'outletId': outletId,
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['token']?.toString() ?? '';
        final partnerJson = data['partner'] != null
            ? (data['partner'] as Map<String, dynamic>)
            : data;
        final partner = DeliveryPartner.fromJson(partnerJson);
        if (token.isNotEmpty) {
          await StorageService.saveSession(token, partner);
        }
        return ApiResponse(success: true, data: data);
      } else {
        String errorMsg = 'Registration failed (${response.statusCode})';
        try {
          final errBody = jsonDecode(response.body);
          if (errBody is Map && errBody['message'] != null) {
            errorMsg = errBody['message'].toString();
          }
        } catch (_) {}
        return ApiResponse(success: false, error: errorMsg);
      }
    } catch (e) {
      return ApiResponse(success: false, error: 'Connection error: Could not reach server at ${ApiConfig.baseUrl}');
    }
  }

  // 2. Duty Status Toggle
  static Future<ApiResponse<DeliveryPartner>> updateStatus(String partnerId, String status) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/delivery-partner/$partnerId/status?status=$status');
      final headers = await _headers();
      final response = await http.put(url, headers: headers).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse(success: true, data: DeliveryPartner.fromJson(data));
      } else {
        return ApiResponse(success: false, error: 'Failed to update status: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse(success: false, error: 'Network error updating status');
    }
  }

  // 3. Location Sync
  static Future<ApiResponse<bool>> updateLocation(String partnerId, double lat, double lng) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/delivery-partner/$partnerId/location');
      final headers = await _headers();
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode({'latitude': lat, 'longitude': lng}),
      ).timeout(const Duration(seconds: 8));
      return ApiResponse(success: response.statusCode == 200, data: response.statusCode == 200);
    } catch (e) {
      return ApiResponse(success: false, error: 'Location sync failed');
    }
  }

  // 4. Get My Deliveries
  static Future<ApiResponse<List<DeliveryAssignment>>> getMyDeliveries(String partnerId) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/delivery-partner/$partnerId/my-deliveries');
      final headers = await _headers();
      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        final assignments = list.map((item) => DeliveryAssignment.fromJson(item as Map<String, dynamic>)).toList();
        return ApiResponse(success: true, data: assignments);
      } else {
        return ApiResponse(success: false, error: 'Failed to fetch deliveries: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse(success: false, error: 'Connection error loading deliveries');
    }
  }

  // 5. Accept Assignment
  static Future<ApiResponse<DeliveryAssignment>> acceptAssignment(String assignmentId, String partnerId) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/delivery-partner/deliveries/$assignmentId/accept?partnerId=$partnerId');
      final headers = await _headers();
      final response = await http.post(url, headers: headers).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse(success: true, data: DeliveryAssignment.fromJson(data));
      } else {
        return ApiResponse(success: false, error: 'Failed to accept order (${response.statusCode})');
      }
    } catch (e) {
      return ApiResponse(success: false, error: 'Network error accepting order');
    }
  }

  // 6. Reject Assignment
  static Future<ApiResponse<DeliveryAssignment>> rejectAssignment(String assignmentId, String partnerId) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/delivery-partner/deliveries/$assignmentId/reject?partnerId=$partnerId');
      final headers = await _headers();
      final response = await http.post(url, headers: headers).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse(success: true, data: DeliveryAssignment.fromJson(data));
      } else {
        return ApiResponse(success: false, error: 'Failed to reject order');
      }
    } catch (e) {
      return ApiResponse(success: false, error: 'Network error rejecting order');
    }
  }

  // 7. Pick up Order
  static Future<ApiResponse<DeliveryAssignment>> pickupOrder(String assignmentId, String partnerId) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/delivery-partner/deliveries/$assignmentId/pickup?partnerId=$partnerId');
      final headers = await _headers();
      final response = await http.post(url, headers: headers).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse(success: true, data: DeliveryAssignment.fromJson(data));
      } else {
        return ApiResponse(success: false, error: 'Pickup confirmation failed');
      }
    } catch (e) {
      return ApiResponse(success: false, error: 'Network error confirming pickup');
    }
  }

  // 8. Complete Delivery
  static Future<ApiResponse<DeliveryAssignment>> completeDelivery(
    String assignmentId,
    String partnerId,
    String otpCode,
    String notes,
  ) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/delivery-partner/deliveries/$assignmentId/deliver?partnerId=$partnerId');
      final headers = await _headers();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'otpCode': otpCode.trim(),
          'notes': notes.trim(),
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse(success: true, data: DeliveryAssignment.fromJson(data));
      } else {
        String err = 'Failed to complete delivery';
        try {
          final errBody = jsonDecode(response.body);
          if (errBody is Map && errBody['message'] != null) {
            err = errBody['message'].toString();
          }
        } catch (_) {}
        return ApiResponse(success: false, error: err);
      }
    } catch (e) {
      return ApiResponse(success: false, error: 'Network error completing delivery');
    }
  }

  // 9. Order Details & Items Lookup (Real items from POS/Kitchen)
  static Future<ApiResponse<OrderDetail>> getOrderWithItems(String orderId) async {
    try {
      final headers = await _headers();

      // Fetch order
      final orderUrl = Uri.parse('${ApiConfig.baseUrl}/orders/$orderId');
      final orderRes = await http.get(orderUrl, headers: headers).timeout(const Duration(seconds: 8));

      // Fetch items
      final itemsUrl = Uri.parse('${ApiConfig.baseUrl}/orders/$orderId/items');
      final itemsRes = await http.get(itemsUrl, headers: headers).timeout(const Duration(seconds: 8));

      List<OrderItemDetail> itemsList = [];
      if (itemsRes.statusCode == 200) {
        final itemsData = jsonDecode(itemsRes.body) as List;
        itemsList = itemsData.map((it) => OrderItemDetail.fromJson(it as Map<String, dynamic>)).toList();
      }

      if (orderRes.statusCode == 200) {
        final orderData = jsonDecode(orderRes.body) as Map<String, dynamic>;
        final orderDetail = OrderDetail.fromJson(orderData, itemsList);
        return ApiResponse(success: true, data: orderDetail);
      } else {
        return ApiResponse(
          success: true,
          data: OrderDetail(
            orderId: orderId,
            orderNumber: orderId.length > 6 ? 'ORD-${orderId.substring(0, 6).toUpperCase()}' : 'ORD-$orderId',
            items: itemsList,
          ),
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Could not load order details',
        data: OrderDetail(
          orderId: orderId,
          orderNumber: orderId.length > 6 ? 'ORD-${orderId.substring(0, 6).toUpperCase()}' : 'ORD-$orderId',
          items: [],
        ),
      );
    }
  }

  // 10. Partner Live Statistics
  static Future<ApiResponse<DeliveryPartnerStats>> getPartnerStats(String partnerId) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/delivery-partner/$partnerId/stats');
      final headers = await _headers();
      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse(success: true, data: DeliveryPartnerStats.fromJson(data));
      }
      return ApiResponse(success: false, error: 'Failed to fetch partner stats');
    } catch (e) {
      return ApiResponse(success: false, error: 'Network error loading stats');
    }
  }

  // 11. Active Assignment Direct Lookup
  static Future<ApiResponse<DeliveryAssignment?>> getActiveAssignment(String partnerId) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/delivery-partner/$partnerId/active-assignment');
      final headers = await _headers();
      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse(success: true, data: DeliveryAssignment.fromJson(data));
      } else if (response.statusCode == 204) {
        return ApiResponse(success: true, data: null);
      }
      return ApiResponse(success: false, error: 'No active delivery');
    } catch (e) {
      return ApiResponse(success: false, error: 'Network error loading active assignment');
    }
  }

  // 12. Partner Profile Refresh
  static Future<ApiResponse<DeliveryPartner>> getPartnerProfile(String partnerId) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/delivery-partner/$partnerId');
      final headers = await _headers();
      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse(success: true, data: DeliveryPartner.fromJson(data));
      }
      return ApiResponse(success: false, error: 'Failed to fetch partner profile');
    } catch (e) {
      return ApiResponse(success: false, error: 'Network error loading partner profile');
    }
  }
}
