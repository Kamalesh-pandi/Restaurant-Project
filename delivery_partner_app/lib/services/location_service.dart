import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class LocationService {
  static Timer? _syncTimer;
  static double currentLat = 12.971598;
  static double currentLng = 77.594566;
  static DateTime? lastSyncTime;
  static final _random = Random();

  static final ValueNotifier<Map<String, dynamic>> locationNotifier = ValueNotifier({
    'latitude': currentLat,
    'longitude': currentLng,
    'lastSync': null,
  });

  static void startTracking(String partnerId, {int intervalSeconds = 20}) {
    stopTracking();
    // Immediate first ping
    _pingLocation(partnerId);

    _syncTimer = Timer.periodic(Duration(seconds: intervalSeconds), (timer) {
      _pingLocation(partnerId);
    });
  }

  static void stopTracking() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  static Future<void> _pingLocation(String partnerId) async {
    if (partnerId.isEmpty) return;

    // Small jitter to simulate movement along the road
    final dLat = (_random.nextDouble() - 0.48) * 0.0008;
    final dLng = (_random.nextDouble() - 0.48) * 0.0008;
    currentLat += dLat;
    currentLng += dLng;
    lastSyncTime = DateTime.now();

    locationNotifier.value = {
      'latitude': currentLat,
      'longitude': currentLng,
      'lastSync': lastSyncTime,
    };

    await ApiService.updateLocation(partnerId, currentLat, currentLng);
  }
}
