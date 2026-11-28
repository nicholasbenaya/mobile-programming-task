import 'package:ronda_app/domain/models/enums.dart';
import 'package:ronda_app/domain/models/sos_event.dart';

/// Contract for emergency SOS dispatch, live response lifecycle, and FCM device token registration.
abstract interface class SosRepository {
  Future<SosEvent> triggerSos({
    required String siteId,
    SosCategory category = SosCategory.darurat,
    required double latitude,
    required double longitude,
    String addressNote = '',
    String note = '',
  });

  Stream<List<SosEvent>> watchActiveSos(String siteId);

  Stream<List<SosEvent>> watchSosHistory(
    String siteId, {
    int limit = 50,
  });

  Future<SosEvent> acknowledgeSos(String sosId);

  Future<SosEvent> markOnScene(String sosId);

  Future<SosEvent> resolveSos({
    required String sosId,
    required String resolutionNote,
    String? localPhotoPath,
  });

  Future<SosEvent> cancelFalseAlarm({
    required String sosId,
    required String cancelReason,
  });

  Future<void> registerDeviceFcmToken({
    required String fcmToken,
    required DevicePlatform platform,
  });

  Future<void> removeDeviceFcmToken(String fcmToken);
}
