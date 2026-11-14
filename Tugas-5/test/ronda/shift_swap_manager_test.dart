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

      // 2. Calon pengganti menyetujui
      ShiftSwapManager.respondByTargetUser(
        request: request,
        respondingUserId: calonPengganti.id,
        isAccepted: true,
      );

      expect(request.status, equals(ShiftSwapStatus.acceptedByTarget));

      // 3. Admin RT mengesahkan
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
  });
}
