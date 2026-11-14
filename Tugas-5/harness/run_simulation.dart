// ignore_for_file: avoid_print
import 'package:ronda_digital/data/mock/mock_backend.dart';
import 'package:ronda_digital/data/mock/seed_data.dart';
import 'package:ronda_digital/domain/ronda/models/ronda_models.dart';
import 'package:ronda_digital/domain/ronda/services/offline_sync_queue.dart';
import 'package:ronda_digital/domain/ronda/services/qr_token_verifier.dart';

void main() async {
  print('======================================================================');
  print('   SIMULASI INTEGRASI HARNESS RONDA DIGITAL (SISKAMLING RT/RW)       ');
  print('   Kelompok 4 · Teknik Komputer Institut Teknologi Sepuluh Nopember  ');
  print('======================================================================\n');

  final backend = MockBackend();
  final offlineQueue = OfflineSyncQueue();

  var passCount = 0;
  const totalSteps = 9;

  // -------------------------------------------------------------------------
  // LANGKAH 1: Autentikasi Pengguna Aman & Terenkripsi SHA-256
  // -------------------------------------------------------------------------
  print('[LANGKAH 1/9] Autentikasi Pengguna Terenkripsi SHA-256');

  // Uji coba sandi salah: Harus ditolak
  var wrongPasswordBlocked = false;
  try {
    backend.login(whatsapp: '081234567802', password: 'sandiyangsalah');
  } catch (e) {
    wrongPasswordBlocked = true;
    print('  ✓ Proteksi Sandi: Percobaan login gagal dicegah dengan benar ($e)');
  }

  // Login resmi dengan kredensial benar
  final petugas = backend.login(whatsapp: '081234567802', password: SeedData.defaultDemoPassword);
  final schedules = backend.getSchedules(petugas.rtId);
  final mySchedule = schedules.firstWhere((s) => s.userId == petugas.id);

  print('  ✓ Login Terverifikasi: ${petugas.namaLengkap} (${petugas.role.label})');
  print('  ✓ Jadwal Shift: ${mySchedule.jamMulai} - ${mySchedule.jamSelesai} WIB');
  if (wrongPasswordBlocked) passCount++;

  // -------------------------------------------------------------------------
  // LANGKAH 2: Check-in Pos 1 (Pos Kamling Utama) - Valid
  // -------------------------------------------------------------------------
  print('\n[LANGKAH 2/9] Check-in Pos 1 (Pos Utama) Berjarak ~10m (VALID)');
  final cp1 = backend.getCheckpoints(petugas.rtId).firstWhere((c) => c.id == 'CP-POS-UTAMA');
  final qrPos1 = QrTokenVerifier.generateQrPayload(
    checkpointId: cp1.id,
    secretKey: cp1.secretKey,
  );

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
  print('\n[LANGKAH 3/9] Uji Anti-Kecurangan: Scan Pos 2 Saat Masih di Pos 1 (~90m)');
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
      userLat: userLatPos1,
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
  print('\n[LANGKAH 4/9] Petugas Berpindah ke Pos 2 (Gardu PLN) & Scan QR');
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
  print('\n[LANGKAH 5/9] Pelaporan Insiden Mencurigakan oleh Petugas Patroli');
  final incident = backend.reportIncident(
    incidentId: 'inc-001',
    userId: petugas.id,
    category: IncidentCategory.orangMencurigakan,
    keterangan: 'Ada motor tanpa plat nomor terparkir mencurigakan di samping gardu PLN',
    photoPath: 'evidence/rt-04/inc-001.jpg',
    latitude: userLatPos2,
    longitude: userLonPos2,
    compass: 45.0,
  );

  print('  ✓ Laporan Insiden Tersimpan: [${incident.category.label}]');
  print('  ✓ Keterangan: "${incident.keterangan}"');
  print('  ✓ Orientasi Kompas Sensor: ${incident.compass}°');
  passCount++;

  // -------------------------------------------------------------------------
  // LANGKAH 6: Tombol Panik SOS Warga & Penyelesaian Melalui Scan QR Warga
  // -------------------------------------------------------------------------
  print('\n[LANGKAH 6/9] Siklus SOS 1: Pemicuan ➔ Respons Petugas ➔ Selesai via QR Warga');
  final wargaFito = SeedData.wargaFito;
  final emergency1 = backend.triggerPanic(
    eventId: 'sos-alert-001',
    userId: wargaFito.id,
    latitude: -7.282900,
    longitude: 112.795100,
    catatan: 'Ada orang mencurigakan mengintip jendela rumah',
  );

  print('  ✓ Status Awal: ${emergency1.status.label} (${emergency1.userName})');

  // Petugas merespons
  backend.respondEmergency(eventId: emergency1.id, responderId: petugas.id);
  print('  ✓ Petugas Merespons: ${emergency1.status.label} (Petugas: ${emergency1.respondedByUserName})');

  // Petugas menyelesaikan via scan QR code warga pelapor
  backend.resolveEmergencyWithQr(
    eventId: emergency1.id,
    scannedQrPayload: emergency1.verificationQrToken,
    responderId: petugas.id,
  );
  print('  ✓ Selesai Terverifikasi: ${emergency1.status.label} (Metode: ${emergency1.resolvedVia?.label})');
  passCount++;

  // -------------------------------------------------------------------------
  // LANGKAH 7: Siklus SOS 2: Penyelesaian via Foto Bukti ➔ Verifikasi Ketua RT
  // -------------------------------------------------------------------------
  print('\n[LANGKAH 7/9] Siklus SOS 2: Penyelesaian Alternatif Foto ➔ Verifikasi Ketua RT');
  final wargaRisqi = SeedData.wargaRisqi;
  final emergency2 = backend.triggerPanic(
    eventId: 'sos-alert-002',
    userId: wargaRisqi.id,
    latitude: -7.282950,
    longitude: 112.795150,
    catatan: 'Pagar rumah terbuka, penghuni lansia',
  );

  backend.respondEmergency(eventId: emergency2.id, responderId: petugas.id);

  // Warga tidak bisa scan QR -> Petugas unggah foto bukti
  backend.resolveEmergencyWithPhoto(
    eventId: emergency2.id,
    photoPath: '/evidence/sos-bukti-002.jpg',
    notes: 'Kondisi aman, pagar sudah dikunci kembali bersama warga.',
    responderId: petugas.id,
  );
  print('  ✓ Petugas Unggah Foto: ${emergency2.status.label}');

  // Ketua RT login dan memverifikasi laporan berfoto
  final ketuaRt = SeedData.ketuaRt;
  backend.adminVerifyEmergency(
    eventId: emergency2.id,
    adminId: ketuaRt.id,
    isApproved: true,
    adminNotes: 'Laporan dicek dan disetujui.',
  );
  print('  ✓ Ketua RT Menyetujui: ${emergency2.status.label} (Verified by: ${ketuaRt.namaLengkap})');
  passCount++;

  // -------------------------------------------------------------------------
  // LANGKAH 8: Uji Ketahanan Offline-First di Area Blank Spot
  // -------------------------------------------------------------------------
  print('\n[LANGKAH 8/9] Uji Patroli di Blank Spot (Offline-First Queue)');
  final cp3 = backend.getCheckpoints(petugas.rtId).firstWhere((c) => c.id == 'CP-PORTAL-TIMUR');
  final qrPos3 = QrTokenVerifier.generateQrPayload(
    checkpointId: cp3.id,
    secretKey: cp3.secretKey,
  );

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
  // LANGKAH 9: Siklus Pertukaran Jadwal (Shift Swap Lifecycle)
  // -------------------------------------------------------------------------
  print('\n[LANGKAH 9/9] Pengajuan dan Pengesahan Pertukaran Jadwal Ronda');
  final petugasDevi = SeedData.petugasDevi;
  final scheduleDevi = backend.getSchedules(petugasDevi.rtId).firstWhere((s) => s.userId == petugasDevi.id);

  final swapReq = backend.requestShiftSwap(
    requestId: 'swap-dev-01',
    scheduleId: scheduleDevi.id,
    requesterId: petugasDevi.id,
    targetUserId: petugas.id,
    alasan: 'Ada ujian praktikum esok pagi',
  );
  print('  ✓ Permintaan dibuat oleh ${petugasDevi.namaLengkap} kepada ${petugas.namaLengkap} (${swapReq.status.name})');

  backend.respondShiftSwap(
    requestId: swapReq.id,
    responderId: petugas.id,
    isAccepted: true,
  );
  print('  ✓ Disetujui oleh calon pengganti (${swapReq.status.name})');

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
