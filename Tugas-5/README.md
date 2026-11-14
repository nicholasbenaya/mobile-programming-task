# Tugas 5 — Ronda Digital
## Siskamling Modern untuk Keamanan Lingkungan RT/RW
**Kelompok 4 · Teknik Komputer ITS**

---

### Anggota Kelompok
| No | Nama | NRP | Peran Lingkungan |
|---|---|---|---|
| 1 | Nicholas Benaya | 5024241050 | Ketua RT (Admin) |
| 2 | Jordi | 5024241029 | Petugas Ronda |
| 3 | Devi Putri Sekar Arum | 5024241049 | Petugas Ronda |
| 4 | Fito Dwi Ardiansah | 5024241053 | Warga Lingkungan |
| 5 | Muhamad Risqi Aditiya | 5024221010 | Warga Lingkungan |

---

## 1. Latar Belakang & Masalah Ronda Konvensional
1. **Jadwal sering lupa & tukar giliran repot**: Miskomunikasi koordinasi di grup WhatsApp.
2. **Tanpa bukti patroli fisik**: Tidak ada catatan presisi siapa hadir dan berkeliling.
3. **Peringatan lambat saat darurat**: Sulit menyebarkan alarm bahaya (maling/kebakaran) secara cepat ke warga sekitar.
4. **Ketiadaan riwayat laporan**: Kejadian hilang tanpa arsip terstruktur.

## 2. Solusi Ronda Digital
1. **Jadwal Otomatis**: Distribusi shift adil, pengingat terjadwal (H-1 & H-2 jam), dan alur tukar jadwal resmi (*Shift Swap*).
2. **Check-in QR Bertanda Waktu + Validasi Radius GPS**: Pemindaian titik checkpoint anti-titip-absen dengan formula Haversine ($\le 25\text{ m}$).
3. **Tombol Panik (SOS)**: Penekanan tahan 3 detik memancarkan alarm sirine instan ke seluruh ponsel warga via topik FCM RT.
4. **Log Patroli & Laporan Insiden Berfoto**: Pendataan temuan mencurigakan berkoordinat GPS dan orientasi kompas perangkat.
5. **Dukungan Offline-First**: Patroli di sudut *blank spot* tetap tersimpan dan otomatis tersinkronisasi saat sinyal pulih.

---

## 3. Arsitektur Teknis
- **Aplikasi Mobile**: Flutter (Android & iOS)
- **Backend**: Node.js + Express + TypeScript + Prisma ORM
- **Database**: MySQL
- **Notifikasi**: Firebase Cloud Messaging (FCM Topic per RT)
- **Validasi Keamanan**: QR Time-based token (HMAC-SHA256) + Geofencing Haversine GPS

---

## 4. Cara Menjalankan & Menguji

Masuk ke folder `Tugas-5`:

```bash
cd Tugas-5
```

### 1. Ambil Dependency
```bash
flutter pub get
```

### 2. Jalankan Test Suite Otomatis (25 Tests)
```bash
flutter test test/ronda/
```

### 3. Jalankan Skenario Simulasi Patroli 1 Malam Penuh
```bash
dart run harness/run_simulation.dart
```

### 4. Verifikasi 1-Klik (Test + Simulasi + Static Analysis)
```powershell
powershell -ExecutionPolicy Bypass -File harness/verify.ps1
```

Dokumentasi teknis lengkap dan Product Requirement Document dapat dibaca di:
- [`PRD.md`](PRD.md)
- [`HARNESS.md`](HARNESS.md)
