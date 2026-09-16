import 'dart:async';
import 'package:flutter/material.dart';
import '../models/delivery_assignment.dart';
import '../models/delivery_partner_stats.dart';
import '../models/order_details.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';

class DeliveryProvider extends ChangeNotifier {
  List<DeliveryAssignment> _deliveries = [];
  DeliveryAssignment? _activeAssignment;
  DeliveryAssignment? _incomingAssignment;
  OrderDetail? _currentOrderDetail;
  DeliveryPartnerStats? _stats;
  bool _isLoading = false;
  String? _errorMessage;

  Timer? _pollingTimer;
  final Set<String> _notifiedAssignmentIds = {};

  List<DeliveryAssignment> get deliveries => _deliveries;
  DeliveryAssignment? get activeAssignment => _activeAssignment;
  DeliveryAssignment? get incomingAssignment => _incomingAssignment;
  OrderDetail? get currentOrderDetail => _currentOrderDetail;
  DeliveryPartnerStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Active delivery check
  bool get hasActiveDelivery => _activeAssignment != null;

  // Real pending assignments waiting for acceptance
  List<DeliveryAssignment> get pendingAssignments =>
      _deliveries.where((d) => d.isAssigned).toList();

  // Real ongoing/accepted/picked-up assignments
  List<DeliveryAssignment> get activeOrders =>
      _deliveries.where((d) => d.isActive).toList();

  // Completed deliveries
  List<DeliveryAssignment> get completedDeliveries {
    return _deliveries.where((d) => d.isDelivered).toList()
      ..sort((a, b) => (b.deliveredAt ?? '').compareTo(a.deliveredAt ?? ''));
  }

  // Live Earnings & Performance Stats (Powered by backend stats + real deliveries)
  int get todayDeliveriesCount {
    if (_stats != null && _stats!.todayDeliveriesCount > 0) {
      return _stats!.todayDeliveriesCount;
    }
    final now = DateTime.now();
    return _deliveries.where((d) {
      if (!d.isDelivered || d.deliveredAt == null) return false;
      try {
        final dt = DateTime.parse(d.deliveredAt!);
        return dt.year == now.year && dt.month == now.month && dt.day == now.day;
      } catch (_) {
        return false;
      }
    }).length;
  }

  double get todayFeesEarned {
    final now = DateTime.now();
    return _deliveries.where((d) {
      if (!d.isDelivered || d.deliveredAt == null) return false;
      try {
        final dt = DateTime.parse(d.deliveredAt!);
        return dt.year == now.year && dt.month == now.month && dt.day == now.day;
      } catch (_) {
        return false;
      }
    }).fold(0.0, (sum, d) => sum + d.deliveryFee);
  }

  double get todayTipsEarned {
    if (_stats != null && _stats!.todayTips > 0) {
      return _stats!.todayTips;
    }
    final now = DateTime.now();
    return _deliveries.where((d) {
      if (!d.isDelivered || d.deliveredAt == null) return false;
      try {
        final dt = DateTime.parse(d.deliveredAt!);
        return dt.year == now.year && dt.month == now.month && dt.day == now.day;
      } catch (_) {
        return false;
      }
    }).fold(0.0, (sum, d) => sum + d.tipAmount);
  }

  double get todayTotalEarnings {
    if (_stats != null && _stats!.todayEarnings > 0) {
      return _stats!.todayEarnings;
    }
    return todayFeesEarned + todayTipsEarned;
  }

  double get allTimeTotalEarnings {
    if (_stats != null && _stats!.allTimeEarnings > 0) {
      return _stats!.allTimeEarnings;
    }
    return _deliveries
        .where((d) => d.isDelivered)
        .fold(0.0, (sum, d) => sum + d.totalEarning);
  }

  int get weeklyDeliveriesCount => _stats?.weeklyDeliveriesCount ?? 0;
  double get weeklyEarnings => _stats?.weeklyEarnings ?? 0.0;
  double get completionRate => _stats?.completionRate ?? 100.0;
  double get totalDistanceKm => _stats?.totalDistanceKm ?? (completedDeliveries.length * 3.2);

  void startPolling(String partnerId, {bool isOnline = true}) {
    stopPolling();
    if (!isOnline) return;

    fetchDeliveries(partnerId);
    fetchPartnerStats(partnerId);
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      fetchDeliveries(partnerId);
      fetchPartnerStats(partnerId);
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> fetchPartnerStats(String partnerId) async {
    if (partnerId.isEmpty) return;
    final res = await ApiService.getPartnerStats(partnerId);
    if (res.success && res.data != null) {
      _stats = res.data;
      notifyListeners();
    }
  }

  Future<void> fetchDeliveries(String partnerId) async {
    if (partnerId.isEmpty) return;

    final res = await ApiService.getMyDeliveries(partnerId);
    if (res.success && res.data != null) {
      _deliveries = res.data!;

      // Check for active assignments: ASSIGNED, ACCEPTED, PICKED_UP
      final activeList = _deliveries.where((d) => d.isActive).toList();

      if (activeList.isNotEmpty) {
        final latestActive = activeList.first;
        _activeAssignment = latestActive;

        // If newly ASSIGNED and not yet alerted to rider
        if (latestActive.isAssigned && !_notifiedAssignmentIds.contains(latestActive.assignmentId)) {
          _notifiedAssignmentIds.add(latestActive.assignmentId);
          _incomingAssignment = latestActive;
          AudioService.playOrderAlert();
        }

        // Auto load order details if not loaded or changed
        if (_currentOrderDetail == null || _currentOrderDetail!.orderId != latestActive.orderId) {
          loadOrderDetail(latestActive.orderId);
        }
      } else {
        _activeAssignment = null;
        if (_incomingAssignment != null) {
          _incomingAssignment = null;
          AudioService.stopAlert();
        }
      }

      notifyListeners();
    }
  }

  Future<void> loadOrderDetail(String orderId) async {
    final res = await ApiService.getOrderWithItems(orderId);
    if (res.success && res.data != null) {
      _currentOrderDetail = res.data;
      notifyListeners();
    }
  }

  Future<bool> acceptAssignment(String assignmentId, String partnerId) async {
    AudioService.stopAlert();
    _incomingAssignment = null;
    _isLoading = true;
    notifyListeners();

    final res = await ApiService.acceptAssignment(assignmentId, partnerId);
    _isLoading = false;

    if (res.success && res.data != null) {
      _activeAssignment = res.data;
      await fetchDeliveries(partnerId);
      return true;
    } else {
      _errorMessage = res.error ?? 'Failed to accept order';
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectAssignment(String assignmentId, String partnerId) async {
    AudioService.stopAlert();
    _incomingAssignment = null;
    _isLoading = true;
    notifyListeners();

    final res = await ApiService.rejectAssignment(assignmentId, partnerId);
    _isLoading = false;

    if (res.success) {
      _activeAssignment = null;
      await fetchDeliveries(partnerId);
      return true;
    } else {
      _errorMessage = res.error ?? 'Failed to reject order';
      notifyListeners();
      return false;
    }
  }

  Future<bool> pickupOrder(String assignmentId, String partnerId) async {
    _isLoading = true;
    notifyListeners();

    final res = await ApiService.pickupOrder(assignmentId, partnerId);
    _isLoading = false;

    if (res.success && res.data != null) {
      _activeAssignment = res.data;
      await fetchDeliveries(partnerId);
      return true;
    } else {
      _errorMessage = res.error ?? 'Pickup confirmation failed';
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeDelivery(
    String assignmentId,
    String partnerId,
    String otpCode,
    String notes,
  ) async {
    _isLoading = true;
    notifyListeners();

    final res = await ApiService.completeDelivery(assignmentId, partnerId, otpCode, notes);
    _isLoading = false;

    if (res.success && res.data != null) {
      _activeAssignment = null;
      _currentOrderDetail = null;
      await fetchDeliveries(partnerId);
      await fetchPartnerStats(partnerId);
      return true;
    } else {
      _errorMessage = res.error ?? 'Invalid delivery OTP code';
      notifyListeners();
      return false;
    }
  }

  void dismissIncomingModal() {
    AudioService.stopAlert();
    _incomingAssignment = null;
    notifyListeners();
  }

  void toggleItemCheck(int index) {
    if (_currentOrderDetail != null && index < _currentOrderDetail!.items.length) {
      _currentOrderDetail!.items[index].isChecked = !_currentOrderDetail!.items[index].isChecked;
      notifyListeners();
    }
  }
}
