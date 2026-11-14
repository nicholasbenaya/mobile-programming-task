import 'package:flutter_test/flutter_test.dart';
import 'package:ronda_digital/domain/ronda/models/ronda_models.dart';
import 'package:ronda_digital/domain/ronda/services/sos_event_dispatcher.dart';

void main() {
  group('SosEventDispatcher Tests (Tombol Panik & Alarm FCM)', () {
    late RondaUser pelapor;
    late SosEventDispatcher dispatcher;

    setUp(() {
      pelapor = const RondaUser(
        id: 'user-warga-01',
        rtId: 'rt-04',
        namaLengkap: 'Bpk. Fito Ardiansah',
        nomorWhatsapp: '081299887766',
        alamatRumah: 'Jl. Teknik Mesin No. 44, RT 04',
        role: UserRole.warga,
      );
      dispatcher = SosEventDispatcher(debounceWindowSeconds: 15);
    });

    test('Memicu SOS menghasilkan EmergencyEvent ACTIVE dan Payload FCM Topic RT yang tepat', () {
      final now = DateTime.now();
      const lat = -7.281970;
      const lon = 112.795323;

      final result = dispatcher.triggerPanic(
        eventId: 'sos-ev-001',
        user: pelapor,
        latitude: lat,
        longitude: lon,
        catatan: 'Ada gerak-gerik mencurigakan di depan pagar rumah',
        timestamp: now,
      );

      final event = result.event;
      final payload = result.fcmPayload;

      // Cek Event
      expect(event.id, equals('sos-ev-001'));
      expect(event.userId, equals(pelapor.id));
      expect(event.userName, equals(pelapor.namaLengkap));
      expect(event.userAddress, equals(pelapor.alamatRumah));
      expect(event.latitude, equals(lat));
      expect(event.longitude, equals(lon));
      expect(event.isActive, isTrue);

      // Cek Payload FCM
      expect(payload.topic, equals('rt_rt-04_emergency'));
      expect(payload.priority, equals('high'));
      expect(payload.sound, equals('alarm_siren.mp3'));
      expect(payload.title, contains('DARURAT SISKAMLING'));
      expect(payload.data['type'], equals('EMERGENCY_SOS'));
      expect(payload.data['event_id'], equals('sos-ev-001'));
    });

    test('Anti-Spam Debounce menolak pemicuan berulang dalam jendela waktu yang ditentukan', () {
      final now = DateTime.now();

      // Pemicuan pertama: Sukses
      dispatcher.triggerPanic(
        eventId: 'sos-ev-002',
        user: pelapor,
        latitude: -7.281970,
        longitude: 112.795323,
        timestamp: now,
      );

      // Pemicuan kedua hanya 3 detik kemudian: Harus dicegah
      final rapidTime = now.add(const Duration(seconds: 3));
      expect(
        () => dispatcher.triggerPanic(
          eventId: 'sos-ev-003',
          user: pelapor,
          latitude: -7.281970,
          longitude: 112.795323,
          timestamp: rapidTime,
        ),
        throwsStateError,
      );
    });

    test('Status insiden dapat diselesaikan (RESOLVED) oleh petugas/admin', () {
      final result = dispatcher.triggerPanic(
        eventId: 'sos-ev-004',
        user: pelapor,
        latitude: -7.281970,
        longitude: 112.795323,
      );

      expect(result.event.isActive, isTrue);

      dispatcher.resolveEmergency(result.event);

      expect(result.event.isActive, isFalse);
      expect(result.event.status, equals('RESOLVED'));
      expect(result.event.resolvedAt, isNotNull);
    });
  });
}
