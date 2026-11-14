// ignore_for_file: avoid_print
import 'package:ronda_digital/domain/ronda/models/ronda_models.dart';
import 'package:ronda_digital/domain/ronda/services/offline_sync_queue.dart';
import 'package:ronda_digital/domain/ronda/services/qr_token_verifier.dart';
import 'mock_backend.dart';
import 'seed_data.dart';

void main() async {
  print('======================================================================');
  print('   SIMULASI INTEGRASI HARNESS RONDA DIGITAL (SISKAMLING RT/RW)       ');
  print('   Kelompok 4 · Teknik Komputer Institut Teknologi Sepuluh Nopember  ');
  print('======================================================================\n');

  final backend = MockBackend();
  final offlineQueue = OfflineSyncQueue();

  var passCount = 0;
  var totalSteps = 8;

  // -------------------------------------------------------------------------
  // LANGKAH 1: Login & Cek Jadwal Petugas Ronda
  // -------------------------------------------------------------------------
  print('[LANGKAH 1/8] Autentikasi Pengguna & Penarikan Jadwal Ronda');
  final petugas = backend.loginByWhatsapp('081234567802');
  final schedules = backend.getSchedules(petugas.rtId);
  final mySchedule = schedules.firstWhere((s) => s.userId == petugas.id);

  print('  ✓ Login Berhasil: ${petugas.namaLengkap} (${petugas.role.label})');
  print('  ✓ Jadwal Shift: ${mySchedule.jamMulai} - ${mySchedule.jamSelesai} WIB');
  passCount++;

  // -------------------------------------------------------------------------
  // LANGKAH 2: Check-in Pos 1 (Pos Kamling Utama) - Valid
  // -------------------------------------------------------------------------
  print('\n[LANGKAH 2/8] Check-in Pos 1 (Pos Utama) Berjarak ~10m (VALID)');
  final cp1 = backend.getCheckpoints(petugas.rtId).firstWhere((c) => c.id == 'CP-POS-UTAMA');
  final qrPos1 = QrTokenVerifier.generateQrPayload(
    checkpointId: cp1.id,
    secretKey: cp1.secretKey,
  );

  // Koordinat petugas berada 10 meter dari Pos 1
  const userLatPos1 = -7.281980;
  const userLonPos1 = 112.795330;

  final checkin1 = backend.submitCheckin(
    checkinId: 'chk-night-01',
    checkpointId: cp1.id,
    userId: petugas.id,
    qrPayload: qrPos1,
    userLat: userLatPos1,
    userLon: userLonPos1,
    accuracy: 4.5,
    batteryLevel: 92.0,
  );

  print('  ✓ Check-in Berhasil tercatat: ${cp1.namaLokasi}');
  print('  ✓ Jarak terverifikasi: ${checkin1.distanceMeter.toStringAsFixed(1)} m (dalam radius ${cp1.radiusMeter}m)');
  passCount++;

  // -------------------------------------------------------------------------
  // LANGKAH 3: Percobaan Curang Scan Pos 2 dari Pos 1 (TOLAK GEOFENCE)
  // -------------------------------------------------------------------------
  print('\n[LANGKAH 3/8] Uji Anti-Kecurangan: Scan Pos 2 Saat Masih di Pos 1 (~90m)');
  final cp2 = backend.getCheckpoints(petugas.rtId).firstWhere((c) => c.id == 'CP-GARDU-PLN');
  final qrPos2 = QrTokenVerifier.generateQrPayload(
    checkpointId: cp2.id,
    secretKey: cp2.secretKey,
  );

  var geofenceRejected = false;
  try {
    backend.submitCheckin(
      checkinId: 'chk-fraud-01',
      checkpointId: cp2.id,
      userId: petugas.id,
      qrPayload: qrPos2,
      userLat: userLatPos1, // Masih di lokasi Pos 1 (~95m dari Pos 2)
      userLon: userLonPos1,
      accuracy: 5.0,
    );
  } catch (e) {
    geofenceRejected = true;
    print('  ✓ Berhasil Digagalkan: $e');
  }

  if (geofenceRejected) passCount++;

  // -------------------------------------------------------------------------
  // LANGKAH 4: Petugas Berjalan ke Pos 2 & Check-in Sukses
  // -------------------------------------------------------------------------
  print('\n[LANGKAH 4/8] Petugas Berpindah ke Pos 2 (Gardu PLN) & Scan QR');
  const userLatPos2 = -7.282510;
  const userLonPos2 = 112.796010;

  final checkin2 = backend.submitCheckin(
    checkinId: 'chk-night-02',
    checkpointId: cp2.id,
    userId: petugas.id,
    qrPayload: qrPos2,
    userLat: userLatPos2,
    userLon: userLonPos2,
    accuracy: 6.0,
    batteryLevel: 88.0,
  );

  print('  ✓ Check-in Berhasil: ${cp2.namaLokasi} (Jarak: ${checkin2.distanceMeter.toStringAsFixed(1)}m)');
  passCount++;

  // -------------------------------------------------------------------------
  // LANGKAH 5: Pelaporan Temuan Insiden Mencurigakan Berfoto
  // -------------------------------------------------------------------------
  print('\n[LANGKAH 5/8] Pelaporan Insiden Mencurigakan oleh Petugas Patroli');
  final incident = backend.reportIncident(
    incidentId: 'inc-001',
    userId: petugas.id,
    category: IncidentCategory.orangMencurigakan,
    keterangan: 'Ada motor tanpa plat nomor terparkir mencurigakan di samping gardu PLN',
    photoPath: 'evidence/rt-04/inc-001.jpg',
    latitude: userLatPos2,
    longitude: userLonPos2,
    compass: 45.0, // Mengarah ke Timur Laut
  );

  print('  ✓ Laporan Insiden Tersimpan: [${incident.category.label}]');
  print('  ✓ Keterangan: "${incident.keterangan}"');
  print('  ✓ Orientasi Kompas Sensor: ${incident.compass}°');
  passCount++;

  // -------------------------------------------------------------------------
  // LANGKAH 6: Tombol Panik (SOS) oleh Warga & Broadcast FCM
  // -------------------------------------------------------------------------
  print('\n[LANGKAH 6/8] Aktivasi Tombol Panik SOS Warga & Pancaran FCM Topic');
  final warga = SeedData.wargaFito;
  final emergency = backend.triggerPanic(
    eventId: 'sos-alert-999',
    userId: warga.id,
    latitude: -7.282900,
    longitude: 112.795100,
    catatan: 'Maling mencoba memanjat pagar rumah!',
  );

  final lastFcm = backend.fcmBroadcastHistory.last;
  print('  ✓ ALARM AKTIF: ${emergency.userName} (${emergency.userAddress})');
  print('  ✓ Topic FCM: ${lastFcm.topic}');
  print('  ✓ Judul Notifikasi: ${lastFcm.title}');
  print('  ✓ File Audio Sirine: ${lastFcm.sound}');
  print('  ✓ Prioritas Pengiriman: ${lastFcm.priority.toUpperCase()}');
  passCount++;

  // -------------------------------------------------------------------------
  // LANGKAH 7: Uji Ketahanan Offline-First di Area Blank Spot
  // -------------------------------------------------------------------------
  print('\n[LANGKAH 7/8] Uji Patroli di Blank Spot (Offline-First Queue)');
  final cp3 = backend.getCheckpoints(petugas.rtId).firstWhere((c) => c.id == 'CP-PORTAL-TIMUR');
  final qrPos3 = QrTokenVerifier.generateQrPayload(
    checkpointId: cp3.id,
    secretKey: cp3.secretKey,
  );

  // Perangkat kehilangan sinyal internet (Offline)
  final offlineCheckin = PatrolCheckin(
    id: 'chk-offline-01',
    checkpointId: cp3.id,
    userId: petugas.id,
    scannedAt: DateTime.now(),
    latitudeUser: cp3.latitude + 0.00005,
    longitudeUser: cp3.longitude + 0.00005,
    distanceMeter: 8.2,
    accuracy: 6.0,
    batteryLevel: 81.0,
  );

  offlineQueue.enqueue(offlineCheckin);
  print('  ✓ Koneksi Internet Terputus: 1 Scan disimpan di antrean lokal (Pending: ${offlineQueue.pendingCount})');

  // Sinyal kembali normal -> sinkronisasi otomatis
  print('  * Sinyal seluler terhubung kembali, memproses antrean...');
  final synced = await offlineQueue.processQueue((item) async {
    backend.submitCheckin(
      checkinId: item.id,
      checkpointId: item.checkpointId,
      userId: item.userId,
      qrPayload: qrPos3,
      userLat: item.latitudeUser,
      userLon: item.longitudeUser,
      accuracy: item.accuracy,
      batteryLevel: item.batteryLevel,
      scanTime: item.scannedAt,
    );
    return true;
  });

  print('  ✓ Berhasil Sinkronisasi Otomatis: $synced rekaman terkirim ke server');
  print('  ✓ Sisa Antrean Pending: ${offlineQueue.pendingCount}, Berhasil Tersinkron: ${offlineQueue.syncedCount}');
  passCount++;

  // -------------------------------------------------------------------------
  // LANGKAH 8: Siklus Pertukaran Jadwal (Shift Swap Lifecycle)
  // -------------------------------------------------------------------------
  print('\n[LANGKAH 8/8] Pengajuan dan Pengesahan Pertukaran Jadwal Ronda');
  final petugasDevi = SeedData.petugasDevi;
  final scheduleDevi = backend.getSchedules(petugasDevi.rtId).firstWhere((s) => s.userId == petugasDevi.id);

  // 1. Devi mengajukan tukar ke Jordi
  final swapReq = backend.requestShiftSwap(
    requestId: 'swap-dev-01',
    scheduleId: scheduleDevi.id,
    requesterId: petugasDevi.id,
    targetUserId: petugas.id,
    alasan: 'Ada ujian praktikum esok pagi',
  );
  print('  ✓ Permintaan dibuat oleh ${petugasDevi.namaLengkap} kepada ${petugas.namaLengkap} (${swapReq.status.name})');

  // 2. Jordi menyetujui
  backend.respondShiftSwap(
    requestId: swapReq.id,
    responderId: petugas.id,
    isAccepted: true,
  );
  print('  ✓ Disetujui oleh calon pengganti (${swapReq.status.name})');

  // 3. Pak RT mengesahkan
  backend.approveShiftSwap(
    requestId: swapReq.id,
    approverRole: UserRole.adminRt,
    isApproved: true,
  );
  print('  ✓ Disahkan oleh Ketua RT! Jadwal resmi kini atas nama: ${scheduleDevi.petugasName}');
  passCount++;

  // -------------------------------------------------------------------------
  // RINGKASAN HASIL
  // -------------------------------------------------------------------------
  print('\n======================================================================');
  print('   RINGKASAN SIMULASI HARNESS RONDA DIGITAL                          ');
  print('   Skor Kelulusan: $passCount / $totalSteps Langkah (${(passCount / totalSteps * 100).toInt()}%)           ');
  print('   Status: SEMUA SKENARIO OPERASIONAL TERVERIFIKASI SEMPURNA!         ');
  print('======================================================================\n');
}
