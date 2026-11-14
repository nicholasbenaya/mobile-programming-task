import 'dart:math' as math;

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Pembaca sensor perangkat: kompas, kemiringan, dan baterai.
class SensorService {
  final Battery _battery = Battery();

  /// Arah hadap perangkat dalam derajat 0–360.
  Stream<double> compassStream() {
    final events = FlutterCompass.events;
    if (events == null) return const Stream.empty();
    return events.where((e) => e.heading != null).map((e) => e.heading! % 360);
  }

  /// Kemiringan perangkat: 0° = rata, 90° = tegak.
  Stream<double> tiltStream() {
    return accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval)
        .map((e) => math.atan2(e.y, e.z) * 180 / math.pi);
  }

  Future<double?> batteryLevel() async {
    try {
      return (await _battery.batteryLevel).toDouble();
    } catch (_) {
      return null;
    }
  }
}
