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

/// Pengelola Pemicuan Tombol Panik (SOS) & State Machine Penyelesaian Bertingkat
class SosEventDispatcher {
  SosEventDispatcher({this.debounceWindowSeconds = 30});

  final int debounceWindowSeconds;
  final Map<String, DateTime> _lastTriggerTimestamps = {};

  /// 1. Memicu kejadian darurat baru (Status Awal: BELUM DITANGANI)
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
      status: EmergencyStatus.belumDitangani,
      triggeredAt: now,
    );

    final fcmTopic = 'rt_${user.rtId}_emergency';
    final payload = FcmEmergencyPayload(
      topic: fcmTopic,
      title: '🚨 DARURAT SISKAMLING: ${user.namaLengkap}',
      body: 'Warga membutuhkan bantuan mendesak di ${user.alamatRumah}! Petugas ronda harap segera merespons.',
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
        'verification_qr_token': event.verificationQrToken,
        'sound': 'alarm_siren.mp3',
      },
    );

    return (event: event, fcmPayload: payload);
  }

  /// 2. Petugas Menanggapi / Menuju Lokasi (Status beralih ke: ON-GOING)
  void respondEmergency(
    EmergencyEvent event, {
    required RondaUser responder,
    DateTime? responseTime,
  }) {
    if (event.status == EmergencyStatus.selesai) {
      throw StateError('Insiden ini sudah selesai dan tidak dapat direspons lagi.');
    }
    event.status = EmergencyStatus.onGoing;
    event.respondedAt = responseTime ?? DateTime.now();
    event.respondedByUserId = responder.id;
    event.respondedByUserName = responder.namaLengkap;
  }

  /// 3A. Petugas Menyelesaikan Insiden via Scan QR Warga Pelapor (Status beralih ke: SELESAI)
  void resolveEmergencyWithQr(
    EmergencyEvent event, {
    required String scannedQrPayload,
    required RondaUser responder,
    DateTime? resolvedTime,
  }) {
    if (scannedQrPayload.trim() != event.verificationQrToken.trim()) {
      throw ArgumentError(
        'QR Code tidak valid! Pastikan Anda memindai QR darurat yang ditampilkan di smartphone warga pelapor (${event.userName}).',
      );
    }

    event.status = EmergencyStatus.selesai;
    event.resolvedVia = EmergencyResolutionType.qrWarga;
    event.resolvedAt = resolvedTime ?? DateTime.now();
    event.respondedByUserId ??= responder.id;
    event.respondedByUserName ??= responder.namaLengkap;
  }

  /// 3B. Petugas Menyelesaikan Insiden via Foto Bukti (Status beralih ke: MENUNGGU VERIFIKASI RT)
  void resolveEmergencyWithPhoto(
    EmergencyEvent event, {
    required String photoPath,
    required String notes,
    required RondaUser responder,
    DateTime? actionTime,
  }) {
    if (photoPath.trim().isEmpty) {
      throw ArgumentError('Foto bukti penyelesaian lapangan wajib disertakan.');
    }

    event.status = EmergencyStatus.menungguVerifikasiRt;
    event.resolvedVia = EmergencyResolutionType.fotoBukti;
    event.resolutionPhotoPath = photoPath;
    event.resolutionNotes = notes;
    event.respondedByUserId ??= responder.id;
    event.respondedByUserName ??= responder.namaLengkap;
  }

  /// 4. Ketua RT Memverifikasi Penyelesaian Laporan Berfoto
  void adminVerifyEmergency(
    EmergencyEvent event, {
    required RondaUser admin,
    required bool isApproved,
    String? adminNotes,
    DateTime? verifiedTime,
  }) {
    if (admin.role != UserRole.adminRt) {
      throw StateError('Hanya Ketua RT (Admin) yang memiliki wewenang verifikasi laporan.');
    }

    event.verifiedByAdminId = admin.id;
    event.adminNotes = adminNotes;

    if (isApproved) {
      event.status = EmergencyStatus.selesai;
      event.resolvedAt = verifiedTime ?? DateTime.now();
    } else {
      // Jika ditolak oleh RT, status dikembalikan ke ON-GOING untuk investigasi ulang
      event.status = EmergencyStatus.onGoing;
    }
  }

  /// Helper penutup cepat / pembatalan darurat
  void resolveEmergency(EmergencyEvent event, {DateTime? resolvedTime}) {
    event.status = EmergencyStatus.selesai;
    event.resolvedAt = resolvedTime ?? DateTime.now();
  }
}
