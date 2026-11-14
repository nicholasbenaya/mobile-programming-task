import 'package:ronda_digital/domain/ronda/models/ronda_models.dart';

/// Data Awal / Fixtures untuk Lingkungan Percontohan RT 04 / RW 02 Gebang Putih, Sukolilo (ITS)
class SeedData {
  const SeedData._();

  static const String rtId = 'RT-04-RW-02-SUKOLILO';
  static const String defaultDemoPassword = 'password123';

  // 1. Data Pengguna Berperan Terenkripsi (Kelompok 4 Teknik Komputer ITS)
  static final RondaUser ketuaRt = RondaUser(
    id: 'user-rt-01',
    rtId: rtId,
    namaLengkap: 'Nicholas Benaya (Ketua RT)',
    nomorWhatsapp: '081234567801',
    alamatRumah: 'Jl. Teknik Komputer No. 01, RT 04',
    role: UserRole.adminRt,
    passwordHash: RondaUser.hashPassword(defaultDemoPassword),
    fcmToken: 'fcm_token_admin_rt_01',
  );

  static final RondaUser petugasJordi = RondaUser(
    id: 'user-petugas-01',
    rtId: rtId,
    namaLengkap: 'Jordi (Petugas Ronda)',
    nomorWhatsapp: '081234567802',
    alamatRumah: 'Jl. Gebang Putih Blok A No. 10',
    role: UserRole.petugasRonda,
    passwordHash: RondaUser.hashPassword(defaultDemoPassword),
    fcmToken: 'fcm_token_petugas_jordi',
  );

  static final RondaUser petugasDevi = RondaUser(
    id: 'user-petugas-02',
    rtId: rtId,
    namaLengkap: 'Devi Putri Sekar Arum',
    nomorWhatsapp: '081234567803',
    alamatRumah: 'Jl. Gebang Putih Blok B No. 04',
    role: UserRole.petugasRonda,
    passwordHash: RondaUser.hashPassword(defaultDemoPassword),
    fcmToken: 'fcm_token_petugas_devi',
  );

  static final RondaUser wargaFito = RondaUser(
    id: 'user-warga-01',
    rtId: rtId,
    namaLengkap: 'Fito Dwi Ardiansah (Warga)',
    nomorWhatsapp: '081234567804',
    alamatRumah: 'Jl. Gebang Timur No. 15',
    role: UserRole.warga,
    passwordHash: RondaUser.hashPassword(defaultDemoPassword),
    fcmToken: 'fcm_token_warga_fito',
  );

  static final RondaUser wargaRisqi = RondaUser(
    id: 'user-warga-02',
    rtId: rtId,
    namaLengkap: 'Muhamad Risqi Aditiya (Warga)',
    nomorWhatsapp: '081234567805',
    alamatRumah: 'Jl. Gebang Timur No. 22',
    role: UserRole.warga,
    passwordHash: RondaUser.hashPassword(defaultDemoPassword),
    fcmToken: 'fcm_token_warga_risqi',
  );

  static List<RondaUser> get allUsers => [
        ketuaRt,
        petugasJordi,
        petugasDevi,
        wargaFito,
        wargaRisqi,
      ];

  // 2. Data Titik Checkpoint Pos Patroli Fisik Lingkungan
  static final List<Checkpoint> checkpoints = [
    const Checkpoint(
      id: 'CP-POS-UTAMA',
      rtId: rtId,
      kodeTitik: 'POS-01',
      namaLokasi: 'Pos Kamling Utama & Gapura Masuk',
      latitude: -7.281970,
      longitude: 112.795323,
      radiusMeter: 25.0,
      secretKey: 'key_pos_utama_secret_998',
    ),
    const Checkpoint(
      id: 'CP-GARDU-PLN',
      rtId: rtId,
      kodeTitik: 'POS-02',
      namaLokasi: 'Gardu PLN & Lapangan Warga',
      latitude: -7.282500,
      longitude: 112.796000,
      radiusMeter: 25.0,
      secretKey: 'key_gardu_pln_secret_887',
    ),
    const Checkpoint(
      id: 'CP-PORTAL-TIMUR',
      rtId: rtId,
      kodeTitik: 'POS-03',
      namaLokasi: 'Portal Gang Buntu Timur',
      latitude: -7.283100,
      longitude: 112.795800,
      radiusMeter: 30.0,
      secretKey: 'key_portal_timur_secret_776',
    ),
    const Checkpoint(
      id: 'CP-TAMAN-WARGA',
      rtId: rtId,
      kodeTitik: 'POS-04',
      namaLokasi: 'Balai Pertemuan & Pos Ronda Selatan',
      latitude: -7.282800,
      longitude: 112.794900,
      radiusMeter: 25.0,
      secretKey: 'key_taman_warga_secret_665',
    ),
  ];

  // 3. Data Jadwal Ronda Aktif
  static List<PatrolSchedule> initialSchedules(DateTime baseDate) => [
        PatrolSchedule(
          id: 'SCHED-DAY-1-JORDI',
          rtId: rtId,
          userId: petugasJordi.id,
          petugasName: petugasJordi.namaLengkap,
          tanggalRonda: baseDate,
          jamMulai: '22:00',
          jamSelesai: '04:00',
        ),
        PatrolSchedule(
          id: 'SCHED-DAY-2-DEVI',
          rtId: rtId,
          userId: petugasDevi.id,
          petugasName: petugasDevi.namaLengkap,
          tanggalRonda: baseDate.add(const Duration(days: 1)),
          jamMulai: '22:00',
          jamSelesai: '04:00',
        ),
      ];
}
