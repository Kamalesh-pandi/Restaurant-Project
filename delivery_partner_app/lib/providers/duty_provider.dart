import 'package:flutter/material.dart';
import '../models/delivery_partner.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';

class DutyProvider extends ChangeNotifier {
  String _status = 'OFFLINE'; // OFFLINE, ONLINE, ON_DELIVERY
  bool _isToggling = false;
  String? _errorMessage;

  String get status => _status;
  bool get isOnline => _status == 'ONLINE';
  bool get isOnDelivery => _status == 'ON_DELIVERY';
  bool get isOffline => _status == 'OFFLINE';
  bool get isToggling => _isToggling;
  String? get errorMessage => _errorMessage;

  void initStatus(DeliveryPartner? partner) {
    if (partner != null) {
      _status = partner.status;
      if (_status == 'ONLINE' || _status == 'ON_DELIVERY') {
        LocationService.startTracking(partner.partnerId);
      } else {
        LocationService.stopTracking();
      }
      notifyListeners();
    }
  }

  Future<bool> toggleDuty(DeliveryPartner partner) async {
    final newStatus = _status == 'OFFLINE' ? 'ONLINE' : 'OFFLINE';
    return setStatus(partner, newStatus);
  }

  Future<bool> setStatus(DeliveryPartner partner, String targetStatus) async {
    _isToggling = true;
    _errorMessage = null;
    notifyListeners();

    final res = await ApiService.updateStatus(partner.partnerId, targetStatus);
    _isToggling = false;

    if (res.success && res.data != null) {
      _status = res.data!.status;
      if (_status == 'ONLINE' || _status == 'ON_DELIVERY') {
        LocationService.startTracking(partner.partnerId);
      } else {
        LocationService.stopTracking();
      }
      notifyListeners();
      return true;
    } else {
      _errorMessage = res.error ?? 'Failed to update duty status';
      notifyListeners();
      return false;
    }
  }

  void forceLocalStatus(String newStatus) {
    _status = newStatus;
    notifyListeners();
  }
}
