import 'dart:async';
import 'package:flutter/services.dart';

class AudioService {
  static Timer? _alertLoopTimer;

  static void playOrderAlert() {
    stopAlert();
    // Play immediate sound & vibration
    _triggerAlertBeep();

    // Repeat every 2 seconds until accepted or rejected
    _alertLoopTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _triggerAlertBeep();
    });
  }

  static void _triggerAlertBeep() {
    try {
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 300), () {
        HapticFeedback.heavyImpact();
      });
    } catch (_) {}
  }

  static void stopAlert() {
    _alertLoopTimer?.cancel();
    _alertLoopTimer = null;
  }
}
