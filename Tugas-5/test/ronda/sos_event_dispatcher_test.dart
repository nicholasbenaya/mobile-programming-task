import 'package:flutter_test/flutter_test.dart';
import 'package:ronda_digital/domain/ronda/models/ronda_models.dart';
import 'package:ronda_digital/domain/ronda/services/sos_event_dispatcher.dart';

void main() {
  group('SosEventDispatcher & Multi-Stage SOS Lifecycle Tests', () {
    late RondaUser pelapor;
    late RondaUser petugas;
    late RondaUser ketuaRt;
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

      petugas = const RondaUser(
        id: 'user-petugas-01',
        rtId: 'rt-04',
        namaLengkap: 'Jordi',
        nomorWhatsapp: '081234567802',
        alamatRumah: 'Jl. Gebang Putih Blok A No. 10',
        role: UserRole.petugasRonda,
      );

      ketuaRt = const RondaUser(
        id: 'user-rt-01',
        rtId: 'rt-04',
        namaLengkap: 'Nicholas Benaya',
        nomorWhatsapp: '081234567801',
        alamatRumah: 'Jl. Teknik Komputer No. 01, RT 04',
        role: UserRole.adminRt,
      );

      dispatcher = SosEventDispatcher(debounceWindowSeconds: 15);
    });

    test('Memicu SOS menghasilkan status BELUM_DITANGANI dan Payload FCM Topic RT yang tepat', () {
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
      expect(event.status, equals(EmergencyStatus.belumDitangani));
      expect(event.isActive, isTrue);
      expect(event.verificationQrToken, isNotEmpty);

      // Cek Payload FCM
      expect(payload.topic, equals('rt_rt-04_emergency'));
      expect(payload.priority, equals('high'));
      expect(payload.sound, equals('alarm_siren.mp3'));
      expect(payload.title, contains('DARURAT SISKAMLING'));
      expect(payload.data['type'], equals('EMERGENCY_SOS'));
      expect(payload.data['event_id'], equals('sos-ev-001'));
    });

    test('Siklus Lengkap 1: Petugas Merespons (ON_GOING) dan Menyelesaikan via Scan QR Warga (SELESAI)', () {
      final result = dispatcher.triggerPanic(
        eventId: 'sos-ev-qr-flow',
        user: pelapor,
        latitude: -7.281970,
        longitude: 112.795323,
      );
      final event = result.event;
      expect(event.status, equals(EmergencyStatus.belumDitangani));

      // 1. Petugas menyatakan merespons
      dispatcher.respondEmergency(event, responder: petugas);
      expect(event.status, equals(EmergencyStatus.onGoing));
      expect(event.respondedByUserId, equals(petugas.id));
      expect(event.respondedByUserName, equals(petugas.namaLengkap));
      expect(event.respondedAt, isNotNull);

      // 2. Petugas memindai QR code warga yang salah -> Harus Ditolak
      expect(
        () => dispatcher.resolveEmergencyWithQr(
          event,
          scannedQrPayload: 'QR-PALSU-123',
          responder: petugas,
        ),
        throwsArgumentError,
      );

      // 3. Petugas memindai QR code warga yang valid -> Berhasil SELESAI
      dispatcher.resolveEmergencyWithQr(
        event,
        scannedQrPayload: event.verificationQrToken,
        responder: petugas,
      );
      expect(event.status, equals(EmergencyStatus.selesai));
      expect(event.resolvedVia, equals(EmergencyResolutionType.qrWarga));
      expect(event.resolvedAt, isNotNull);
      expect(event.isActive, isFalse);
    });

    test('Siklus Lengkap 2: Petugas Menyelesaikan via Foto Bukti -> MENUNGGU VERIFIKASI RT -> RT Menyetujui', () {
      final result = dispatcher.triggerPanic(
        eventId: 'sos-ev-photo-flow',
        user: pelapor,
        latitude: -7.281970,
        longitude: 112.795323,
      );
      final event = result.event;

      // 1. Petugas merespons
      dispatcher.respondEmergency(event, responder: petugas);

      // 2. Warga tidak membawa smartphone / lansia, petugas unggah foto bukti
      dispatcher.resolveEmergencyWithPhoto(
        event,
        photoPath: '/evidence/sos-photo-001.jpg',
        notes: 'Situasi aman terkendali, korban didampingi tetangga sebelah',
        responder: petugas,
      );

      // Status masih ON-GOING menunggu verifikasi RT
      expect(event.status, equals(EmergencyStatus.menungguVerifikasiRt));
      expect(event.resolvedVia, equals(EmergencyResolutionType.fotoBukti));
      expect(event.resolutionPhotoPath, equals('/evidence/sos-photo-001.jpg'));
      expect(event.isActive, isTrue); // Belum selesai sebelum di-approve RT!

      // 3. Petugas biasa tidak boleh melakukan approval RT
      expect(
        () => dispatcher.adminVerifyEmergency(event, admin: petugas, isApproved: true),
        throwsStateError,
      );

      // 4. Ketua RT menyetujui laporan
      dispatcher.adminVerifyEmergency(
        event,
        admin: ketuaRt,
        isApproved: true,
        adminNotes: 'Bukti memadai, laporan ditutup.',
      );

      expect(event.status, equals(EmergencyStatus.selesai));
      expect(event.isActive, isFalse);
      expect(event.verifiedByAdminId, equals(ketuaRt.id));
      expect(event.adminNotes, contains('Bukti memadai'));
    });

    test('Siklus 3: Ketua RT Menolak Foto Bukti -> Status Kembali ke ON-GOING untuk Reinvestigasi', () {
      final result = dispatcher.triggerPanic(
        eventId: 'sos-ev-reject-flow',
        user: pelapor,
        latitude: -7.281970,
        longitude: 112.795323,
      );
      final event = result.event;

      dispatcher.respondEmergency(event, responder: petugas);
      dispatcher.resolveEmergencyWithPhoto(
        event,
        photoPath: '/evidence/blur.jpg',
        notes: 'Foto agak buram',
        responder: petugas,
      );

      expect(event.status, equals(EmergencyStatus.menungguVerifikasiRt));

      // RT menolak karena foto tidak jelas
      dispatcher.adminVerifyEmergency(
        event,
        admin: ketuaRt,
        isApproved: false,
        adminNotes: 'Foto terlalu buram. Harap cek kembali rumah pelapor!',
      );

      expect(event.status, equals(EmergencyStatus.onGoing));
      expect(event.isActive, isTrue);
    });

    test('Keamanan Enkripsi Kredensial Pengguna: Hashing Password SHA-256', () {
      const rawPassword = 'password123';
      final hash = RondaUser.hashPassword(rawPassword);
      final user = RondaUser(
        id: 'test-user',
        rtId: 'rt-04',
        namaLengkap: 'Test User',
        nomorWhatsapp: '081234567890',
        alamatRumah: 'Jl. Mawar No. 1',
        role: UserRole.warga,
        passwordHash: hash,
      );

      expect(user.verifyPassword('password123'), isTrue);
      expect(user.verifyPassword('wrongpassword'), isFalse);
      expect(user.verifyPassword(''), isFalse);
    });
  });
}
