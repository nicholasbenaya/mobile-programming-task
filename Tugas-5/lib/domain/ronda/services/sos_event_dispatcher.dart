import '../models/ronda_models.dart';

/// Payload Siap Pancar ke Firebase Cloud Messaging (FCM Topic)
class FcmEmergencyPayload {
  const FcmEmergencyPayload({
    required this.topic,
    required this.title,
    required this.body,
    required this.sound,
    required this.priority,
    required this.data,
  });

  final String topic;
  final String title;
  final String body;
  final String sound;
  final String priority;
  final Map<String, String> data;

  Map<String, dynamic> toJson() => {
        'to': '/topics/$topic',
        'priority': priority,
        'notification': {
          'title': title,
          'body': body,
          'sound': sound,
          'android_channel_id': 'ronda_emergency_channel',
        },
        'data': data,
      };
}

/// Pengelola Pemicuan Tombol Panik (SOS) & Pembuat Payload Broadcast Darurat RT
class SosEventDispatcher {
  SosEventDispatcher({this.debounceWindowSeconds = 30});

  final int debounceWindowSeconds;
  final Map<String, DateTime> _lastTriggerTimestamps = {};

  /// Memicu kejadian darurat baru dan menghasilkan objek event serta payload FCM
  ({EmergencyEvent event, FcmEmergencyPayload fcmPayload}) triggerPanic({
    required String eventId,
    required RondaUser user,
    required double latitude,
    required double longitude,
    String? catatan,
    DateTime? timestamp,
  }) {
    final now = timestamp ?? DateTime.now();

    // Proteksi anti-spam / double tap
    final lastTime = _lastTriggerTimestamps[user.id];
    if (lastTime != null) {
      final elapsed = now.difference(lastTime).inSeconds;
      if (elapsed < debounceWindowSeconds) {
        throw StateError(
          'Alarm darurat baru saja dipicu. Harap tunggu ${debounceWindowSeconds - elapsed} detik sebelum menekan tombol SOS kembali.',
        );
      }
    }

    _lastTriggerTimestamps[user.id] = now;

    final event = EmergencyEvent(
      id: eventId,
      rtId: user.rtId,
      userId: user.id,
      userName: user.namaLengkap,
      userAddress: user.alamatRumah,
      latitude: latitude,
      longitude: longitude,
      catatan: catatan,
      status: 'ACTIVE',
      triggeredAt: now,
    );

    final fcmTopic = 'rt_${user.rtId}_emergency';
    final payload = FcmEmergencyPayload(
      topic: fcmTopic,
      title: '🚨 DARURAT SISKAMLING: ${user.namaLengkap}',
      body: 'Warga membutuhkan bantuan mendesak di ${user.alamatRumah}! Buka peta untuk arah lokasi.',
      sound: 'alarm_siren.mp3',
      priority: 'high',
      data: {
        'type': 'EMERGENCY_SOS',
        'event_id': event.id,
        'rt_id': user.rtId,
        'user_name': user.namaLengkap,
        'user_address': user.alamatRumah,
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'triggered_at': now.toIso8601String(),
        'sound': 'alarm_siren.mp3',
      },
    );

    return (event: event, fcmPayload: payload);
  }

  /// Menandai insiden darurat telah tertangani / dibatalkan
  void resolveEmergency(EmergencyEvent event, {DateTime? resolvedTime}) {
    event.status = 'RESOLVED';
    event.resolvedAt = resolvedTime ?? DateTime.now();
  }
}
