import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/order_timeline_model.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/services/storage_service.dart';

class TrackingController extends GetxController {
  final OrderRepository _orderRepository = Get.find<OrderRepository>();
  final StorageService _storageService = Get.find<StorageService>();

  final RxBool isLoading = true.obs;
  final RxBool isSwitchingOrder = false.obs;
  final RxString orderId = ''.obs;
  final Rxn<OrderTimelineModel> timelineData = Rxn<OrderTimelineModel>();

  // All active/in-progress orders for this customer
  final RxList<OrderModel> activeOrders = <OrderModel>[].obs;
  // All recent orders for switching/history
  final RxList<OrderModel> recentOrders = <OrderModel>[].obs;

  Timer? _pollingTimer;

  @override
  void onInit() {
    super.onInit();
    final argId = (Get.arguments != null && Get.arguments['orderId'] != null)
        ? Get.arguments['orderId'].toString()
        : null;

    loadAllOrdersAndTimeline(preferredOrderId: argId);
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (orderId.value.isNotEmpty) {
        loadAllOrdersAndTimeline(
          preferredOrderId: orderId.value,
          showLoading: false,
        );
      }
    });
  }

  Future<void> loadAllOrdersAndTimeline({
    String? preferredOrderId,
    bool showLoading = true,
  }) async {
    if (showLoading) isLoading.value = true;

    try {
      List<OrderModel> history = [];
      List<OrderModel> active = [];
      final phone = _storageService.user?.phone ?? '';
      if (phone.isNotEmpty) {
        history = await _orderRepository.getOrderHistory(phone);
        recentOrders.assignAll(history);

        // Separate active live orders vs completed/cancelled
        active = history.where((o) {
          final s = (o.orderStatus).toUpperCase();
          return s != 'DELIVERED' &&
              s != 'CANCELLED' &&
              s != 'COMPLETED' &&
              s != 'REJECTED';
        }).toList();
        activeOrders.assignAll(active);
      }

      // Determine target order to display
      String targetId = '';
      if (preferredOrderId != null && preferredOrderId.isNotEmpty) {
        targetId = preferredOrderId;
      } else if (orderId.value.isNotEmpty) {
        targetId = orderId.value;
      } else if (active.isNotEmpty && active.first.id != null) {
        targetId = active.first.id!;
      } else {
        final saved = _storageService.activeOrderId;
        if (saved != null && saved.isNotEmpty) {
          targetId = saved;
        } else if (history.isNotEmpty && history.first.id != null) {
          targetId = history.first.id!;
        }
      }

      if (targetId.isNotEmpty) {
        orderId.value = targetId;
        _storageService.saveActiveOrderId(targetId);
        final res = await _orderRepository.getOrderTimeline(targetId);
        timelineData.value = res;
      }
    } catch (e) {
      debugPrint('Error loading orders and timeline: $e');
      if (orderId.value.isNotEmpty) {
        try {
          final res = await _orderRepository.getOrderTimeline(orderId.value);
          timelineData.value = res;
        } catch (_) {}
      }
    } finally {
      if (showLoading) isLoading.value = false;
    }
  }

  Future<void> selectOrder(String newOrderId) async {
    if (orderId.value == newOrderId && timelineData.value != null) return;

    orderId.value = newOrderId;
    _storageService.saveActiveOrderId(newOrderId);
    isSwitchingOrder.value = true;

    try {
      final res = await _orderRepository.getOrderTimeline(newOrderId);
      timelineData.value = res;
    } catch (e) {
      debugPrint('Error switching timeline for $newOrderId: $e');
    } finally {
      isSwitchingOrder.value = false;
    }
  }

  OrderModel? get currentOrder {
    try {
      return recentOrders.firstWhere((o) => o.id == orderId.value);
    } catch (_) {
      try {
        return activeOrders.firstWhere((o) => o.id == orderId.value);
      } catch (_) {
        return null;
      }
    }
  }

  @override
  void onClose() {
    _pollingTimer?.cancel();
    super.onClose();
  }
}
