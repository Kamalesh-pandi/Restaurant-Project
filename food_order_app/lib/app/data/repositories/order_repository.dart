import '../models/order_model.dart';
import '../models/order_timeline_model.dart';
import '../providers/order_provider.dart';

class OrderRepository {
  final OrderProvider _orderProvider;

  OrderRepository(this._orderProvider);

  Future<String> createOrder(
    OrderModel order, {
    required String name,
    required String phone,
    required String email,
    String? address,
    String? addressId,
    String? notes,
    String paymentMethod = 'RAZORPAY',
  }) async {
    final payload = order.toDirectOrderJson(
      name: name,
      phone: phone,
      email: email,
      address: address,
      addressId: addressId,
      notes: notes,
      paymentMethod: paymentMethod,
    );
    final response = await _orderProvider.createOrder(payload);
    return response['orderId']?.toString() ?? response['id']?.toString() ?? 'ORD-${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<OrderTimelineModel> getOrderTimeline(String orderId) async {
    final data = await _orderProvider.getOrderTimeline(orderId);
    return OrderTimelineModel.fromJson(data);
  }

  Future<List<OrderModel>> getOrderHistory(String phone) async {
    try {
      final listData = await _orderProvider.getOrderHistory(phone);
      final rawOrders = listData.map((item) => OrderModel.fromJson(item as Map<String, dynamic>)).toList();

      final Map<String, OrderModel> uniqueMap = {};
      for (var order in rawOrders) {
        final key = (order.id != null && order.id!.isNotEmpty)
            ? order.id!
            : '${order.grandTotal}_${order.createdAt.millisecondsSinceEpoch}';
        if (!uniqueMap.containsKey(key)) {
          uniqueMap[key] = order;
        }
      }
      return uniqueMap.values.toList();
    } catch (_) {
      return [];
    }
  }
}
