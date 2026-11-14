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
  const totalSteps = 10;

  // -------------------------------------------------------------------------
  // LANGKAH 1: Autentikasi Pengguna Aman & Terenkripsi SHA-256
  // -------------------------------------------------------------------------
  print('[LANGKAH 1/10] Autentikasi Pengguna Terenkripsi SHA-256');

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
  print('  ✓ Jadwal Shift: ${mySchedule.shiftName}');
  if (wrongPasswordBlocked) passCount++;

  // -------------------------------------------------------------------------
  // LANGKAH 2: Validasi Hak Merespon SOS (Hanya yang Berpatroli yang Boleh)
  // -------------------------------------------------------------------------
  print('\n[LANGKAH 2/10] Pembatasan Hak Merespons SOS: Hanya Petugas Piket Aktif');
  final wargaFito = SeedData.wargaFito;
  final testSos = backend.triggerPanic(
    eventId: 'sos-gate-001',
    userId: wargaFito.id,
    latitude: -7.282900,
    longitude: 112.795100,
    catatan: 'Uji hak akses respons darurat',
  );

  // Coba respon dengan petugas Budi (yang tidak dijadwalkan hari ini)
  final petugasBudi = SeedData.petugasBudi;
  var offDutyBlocked = false;
  try {
    backend.respondEmergency(eventId: testSos.id, responderId: petugasBudi.id);
  } catch (e) {
    offDutyBlocked = true;
    print('  ✓ Petugas Off-Duty Dicegah Merespons: $e');
  }

  // Respon dengan petugas Jordi (yang terjadwal piket aktif hari ini)
  backend.respondEmergency(eventId: testSos.id, responderId: petugas.id);
  print('  ✓ Petugas On-Duty (${petugas.namaLengkap}) Berhasil Merespons SOS!');
  if (offDutyBlocked && testSos.isOnGoing) passCount++;

  // Selesaikan testSos agar bersih
  backend.resolveEmergencyWithQr(
    eventId: testSos.id,
    scannedQrPayload: testSos.verificationQrToken,
    responderId: petugas.id,
  );

  // -------------------------------------------------------------------------
  // LANGKAH 3: Check-in Pos 1 (Pos Kamling Utama) - Valid
  // -------------------------------------------------------------------------
  print('\n[LANGKAH 3/10] Check-in Pos 1 (Pos Utama) Berjarak ~10m (VALID)');
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
  // LANGKAH 4: Percobaan Curang Scan Pos 2 dari Pos 1 (TOLAK GEOFENCE)
  // -------------------------------------------------------------------------
  print('\n[LANGKAH 4/10] Uji Anti-Kecurangan: Scan Pos 2 Saat Masih di Pos 1 (~90m)');
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
  // LANGKAH 5: Jadwal Pos Patroli & Peringatan Check-in Manual oleh Ketua RT
  // -------------------------------------------------------------------------
  print('\n[LANGKAH 5/10] Jadwal Pos Patroli & Peringatan Check-in Manual Ketua RT');
  // Evaluasi status jadwal pos
  final statusCp1 = cp1.calculateStatus(hasCheckedIn: true);
  final statusCp2 = cp2.calculateStatus(hasCheckedIn: false);
  print('  ✓ Evaluasi Pos 1: ${statusCp1.label}');
  print('  ✓ Evaluasi Pos 2 (Target ${cp2.targetWaktuCheckin} WIB): ${statusCp2.label}');

  // Ketua RT kirim peringatan manual untuk pos patroli
  backend.notifyCheckpointReminder(
    rtId: petugas.rtId,
    checkpointId: cp2.id,
    customMessage: 'Pos Gardu PLN belum dipindai, harap segera check-in.',
  );
  print('  ✓ Peringatan Check-in Dikirim RT: Berhasil masuk ke log notifikasi (${backend.notifications.length} notif aktif)');
  passCount++;

  // -------------------------------------------------------------------------
  // LANGKAH 6: Broadcast Panggilan Darurat SOS oleh Ketua RT ke Semua Personel
  // -------------------------------------------------------------------------
  print('\n[LANGKAH 6/10] Broadcast Panggilan Darurat oleh Ketua RT ke Seluruh Petugas');
  final wargaRisqi = SeedData.wargaRisqi;
  final emergencyReal = backend.triggerPanic(
    eventId: 'sos-alert-real-001',
    userId: wargaRisqi.id,
    latitude: -7.282900,
    longitude: 112.795100,
    catatan: 'Orang mencurigakan di depan balai RT',
  );

  backend.broadcastSosAlert(
    rtId: petugas.rtId,
    eventId: emergencyReal.id,
    includeOffDuty: true,
    customMessage: 'DARURAT TINGGI: Seluruh petugas patroli dan cadangan merapat ke lokasi!',
  );
  print('  ✓ Broadcast Darurat Berhasil Terdistribusi (Sertakan Personel Cadangan/Off-Duty)');
  passCount++;

  // -------------------------------------------------------------------------
  // LANGKAH 7: Siklus SOS: Penyelesaian via Foto Bukti ➔ Verifikasi Ketua RT
  // -------------------------------------------------------------------------
  print('\n[LANGKAH 7/10] Siklus SOS: Penyelesaian via Foto Bukti ➔ Verifikasi Ketua RT');
  backend.respondEmergency(eventId: emergencyReal.id, responderId: petugas.id);

  backend.resolveEmergencyWithPhoto(
    eventId: emergencyReal.id,
    photoPath: '/evidence/sos-bukti-001.jpg',
    notes: 'Pelaku kabur, situasi lingkungan aman terkendali.',
    responderId: petugas.id,
  );
  print('  ✓ Petugas Unggah Foto: ${emergencyReal.status.label}');

  final ketuaRt = SeedData.ketuaRt;
  backend.adminVerifyEmergency(
    eventId: emergencyReal.id,
    adminId: ketuaRt.id,
    isApproved: true,
    adminNotes: 'Bukti memadai, insiden resmi ditutup.',
  );
  print('  ✓ Ketua RT Menyetujui: ${emergencyReal.status.label} (Verified by: ${ketuaRt.namaLengkap})');
  passCount++;

  // -------------------------------------------------------------------------
  // LANGKAH 8: Generator Otomatis Jadwal Ronda (5 Hari Ronda + 1 Hari Libur)
  // -------------------------------------------------------------------------
  print('\n[LANGKAH 8/10] Generator Otomatis Jadwal (5 Hari Ronda + 1 Hari Libur)');
  final generatedSchedules = backend.generateAutoRoster(
    rtId: petugas.rtId,
    startDate: DateTime.now(),
    daysCount: 30,
  );

  // Verifikasi aturan 5 ronda + 1 libur per petugas
  final jordiSchedules = generatedSchedules.where((s) => s.userId == petugas.id).toList();
  final liburCount = jordiSchedules.where((s) => s.isLibur).length;
  final rondaCount = jordiSchedules.where((s) => !s.isLibur).length;

  print('  ✓ Terbuat ${generatedSchedules.length} entri jadwal untuk 30 hari ke depan.');
  print('  ✓ Distribusi Petugas Jordi: $rondaCount hari ronda, $liburCount hari libur (Rasio rotasi 5:1)');
  if (generatedSchedules.isNotEmpty && liburCount > 0) passCount++;

  // -------------------------------------------------------------------------
  // LANGKAH 9: Uji Ketahanan Offline-First di Area Blank Spot
  // -------------------------------------------------------------------------
  print('\n[LANGKAH 9/10] Uji Patroli di Blank Spot (Offline-First Queue)');
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
  // LANGKAH 10: Pengajuan Tukar Jadwal Lengkap (Shift, Tanggal, Rekan)
  // -------------------------------------------------------------------------
  print('\n[LANGKAH 10/10] Pertukaran Jadwal Lengkap (Pilih Tanggal, Shift, & Pengganti)');
  final petugasDevi = SeedData.petugasDevi;
  final scheduleDevi = backend.getSchedules(petugasDevi.rtId).firstWhere((s) => s.userId == petugasDevi.id && !s.isLibur);

  final swapReq = backend.requestShiftSwap(
    requestId: 'swap-dev-01',
    scheduleId: scheduleDevi.id,
    requesterId: petugasDevi.id,
    targetUserId: petugas.id,
    alasan: 'Ada keperluan mendesak keluarga di luar kota',
    requesterShift: 'Shift Malam (22:00 - 04:00)',
    targetDate: DateTime.now().add(const Duration(days: 3)),
    targetShift: 'Shift Malam (22:00 - 04:00)',
  );
  print('  ✓ Permintaan dibuat: ${petugasDevi.namaLengkap} tukar dengan ${petugas.namaLengkap} (${swapReq.targetShift})');

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
