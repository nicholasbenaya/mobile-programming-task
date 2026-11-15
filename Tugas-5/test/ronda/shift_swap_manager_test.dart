import 'package:flutter_test/flutter_test.dart';
import 'package:ronda_digital/domain/ronda/models/ronda_models.dart';
import 'package:ronda_digital/domain/ronda/services/shift_swap_manager.dart';

void main() {
  group('ShiftSwapManager Tests (State Machine Pertukaran Jadwal)', () {
    late RondaUser petugasAwal;
    late RondaUser calonPengganti;
    late PatrolSchedule schedule;

    setUp(() {
      petugasAwal = const RondaUser(
        id: 'user-01',
        rtId: 'rt-04',
        namaLengkap: 'Petugas Jordi',
        nomorWhatsapp: '081234567890',
        alamatRumah: 'Blok A No. 12',
        role: UserRole.petugasRonda,
      );

      calonPengganti = const RondaUser(
        id: 'user-02',
        rtId: 'rt-04',
        namaLengkap: 'Petugas Devi',
        nomorWhatsapp: '081234567891',
        alamatRumah: 'Blok B No. 05',
        role: UserRole.petugasRonda,
      );

      schedule = PatrolSchedule(
        id: 'sched-101',
        rtId: 'rt-04',
        userId: 'user-01',
        petugasName: 'Petugas Jordi',
        tanggalRonda: DateTime.now().add(const Duration(days: 1)),
      );
    });

    test('Siklus lengkap pertukaran jadwal: Request -> Target Accept -> Admin Approve -> Mutasi Jadwal', () {
      // 1. Pengajuan tukar
      final request = ShiftSwapManager.createRequest(
        requestId: 'req-001',
        schedule: schedule,
        requester: petugasAwal,
        targetUser: calonPengganti,
        alasan: 'Ada tugas dinas luar kota',
      );

      expect(request.status, equals(ShiftSwapStatus.pending));

      // 2. Calon pengganti menyetujui (Peer-to-Peer consent langsung memutasi jadwal)
      ShiftSwapManager.respondByTargetUser(
        request: request,
        respondingUserId: calonPengganti.id,
        isAccepted: true,
        schedule: schedule,
      );

      expect(request.status, equals(ShiftSwapStatus.acceptedByTarget));
      expect(schedule.userId, equals(calonPengganti.id));
      expect(schedule.petugasName, equals(calonPengganti.namaLengkap));

      // 3. Admin RT mengesahkan (opsional / administratif)
      ShiftSwapManager.approveByAdmin(
        request: request,
        schedule: schedule,
        approverRole: UserRole.adminRt,
        isApproved: true,
      );

      expect(request.status, equals(ShiftSwapStatus.approvedByAdmin));

      // 4. Verifikasi bahwa jadwal resmi telah bermutasi ke Petugas Devi
      expect(schedule.userId, equals(calonPengganti.id));
      expect(schedule.petugasName, equals(calonPengganti.namaLengkap));
    });

    test('Jika calon pengganti menolak, status menjadi rejected dan jadwal tidak berubah', () {
      final request = ShiftSwapManager.createRequest(
        requestId: 'req-002',
        schedule: schedule,
        requester: petugasAwal,
        targetUser: calonPengganti,
        alasan: 'Ada urusan keluarga',
      );

      ShiftSwapManager.respondByTargetUser(
        request: request,
        respondingUserId: calonPengganti.id,
        isAccepted: false, // Menolak
      );

      expect(request.status, equals(ShiftSwapStatus.rejected));
      expect(schedule.userId, equals(petugasAwal.id));
    });

    test('Gagal mengajukan pertukaran jika menunjuk diri sendiri', () {
      expect(
        () => ShiftSwapManager.createRequest(
          requestId: 'req-003',
          schedule: schedule,
          requester: petugasAwal,
          targetUser: petugasAwal, // Diri sendiri
          alasan: 'Iseng',
        ),
        throwsArgumentError,
      );
    });

    test('Warga non-admin tidak berhak mengesahkan pertukaran', () {
      final request = ShiftSwapManager.createRequest(
        requestId: 'req-004',
        schedule: schedule,
        requester: petugasAwal,
        targetUser: calonPengganti,
        alasan: 'Sakit flu',
      );

      ShiftSwapManager.respondByTargetUser(
        request: request,
        respondingUserId: calonPengganti.id,
        isAccepted: true,
      );

      expect(
        () => ShiftSwapManager.approveByAdmin(
          request: request,
          schedule: schedule,
          approverRole: UserRole.warga, // Bukan admin
          isApproved: true,
        ),
        throwsStateError,
      );
    });

    test('Gagal mengajukan jika sudah ada permintaan pending pada jadwal yang sama', () {
      final existingReq = ShiftSwapManager.createRequest(
        requestId: 'req-005',
        schedule: schedule,
        requester: petugasAwal,
        targetUser: calonPengganti,
        alasan: 'Urusan pertama',
      );

      expect(
        () => ShiftSwapManager.createRequest(
          requestId: 'req-006',
          schedule: schedule,
          requester: petugasAwal,
          targetUser: calonPengganti,
          alasan: 'Urusan kedua (duplikat pending)',
          existingSwaps: [existingReq],
        ),
        throwsStateError,
      );
    });

    test('Gagal mengajukan jika melewati batas waktu H-3 jam sebelum jam dinas dimulai', () {
      final lateSchedule = PatrolSchedule(
        id: 'sched-late',
        rtId: 'rt-04',
        userId: 'user-01',
        petugasName: 'Petugas Jordi',
        tanggalRonda: DateTime.now(),
        jamMulai: '22:00',
      );

      // Simulasikan waktu pengajuan pada jam 20:30 (H-1.5 jam < H-3 jam)
      final lateNow = DateTime(
        lateSchedule.tanggalRonda.year,
        lateSchedule.tanggalRonda.month,
        lateSchedule.tanggalRonda.day,
        20,
        30,
      );

      expect(
        () => ShiftSwapManager.createRequest(
          requestId: 'req-007',
          schedule: lateSchedule,
          requester: petugasAwal,
          targetUser: calonPengganti,
          alasan: 'Mendadak',
          createdAt: lateNow,
        ),
        throwsStateError,
      );
    });

    test('Permintaan otomatis menjadi expired jika direspons setelah melewati batas waktu H-3 jam', () {
      final futureSchedule = PatrolSchedule(
        id: 'sched-future',
        rtId: 'rt-04',
        userId: 'user-01',
        petugasName: 'Petugas Jordi',
        tanggalRonda: DateTime.now().add(const Duration(days: 1)),
        jamMulai: '22:00',
      );

      final request = ShiftSwapManager.createRequest(
        requestId: 'req-008',
        schedule: futureSchedule,
        requester: petugasAwal,
        targetUser: calonPengganti,
        alasan: 'Tukar giliran',
      );

      // Rekan merespon pada jam 21:00 hari H (hanya H-1 jam sebelum shift)
      final expiredResponseTime = DateTime(
        futureSchedule.tanggalRonda.year,
        futureSchedule.tanggalRonda.month,
        futureSchedule.tanggalRonda.day,
        21,
        0,
      );

      expect(
        () => ShiftSwapManager.respondByTargetUser(
          request: request,
          respondingUserId: calonPengganti.id,
          isAccepted: true,
          schedule: futureSchedule,
          responseTime: expiredResponseTime,
        ),
        throwsStateError,
      );

      expect(request.status, equals(ShiftSwapStatus.expired));
      // Jadwal tidak boleh bermutasi karena sudah kedaluwarsa
      expect(futureSchedule.userId, equals(petugasAwal.id));
    });
  });
}
