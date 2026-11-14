# HARNESS PENGEMBANGAN & PENGUJIAN: RONDA DIGITAL
## Kelompok 4 · Teknik Komputer Institut Teknologi Sepuluh Nopember

---

Dokumen ini menjelaskan arsitektur, struktur pengujian otomatis, dan alat simulasi (*test & development harness*) yang telah dibuat untuk mempercepat transformasi dari **SensorLog** menjadi aplikasi **Ronda Digital**.

---

## 1. Struktur Harness & Modul Domain

Seluruh logika bisnis inti, aturan validasi, dan mesin proteksi anti-fraud telah dimodelkan dalam bentuk kode mandiri (*domain layer*) yang tidak terikat langsung pada framework UI, sehingga dapat diuji secara otomatis 100%:

```
Tugas-5/
├── lib/
│   └── domain/
│       └── ronda/
│           ├── models/
│           │   └── ronda_models.dart          # Entitas: User, Role, Checkpoint, Schedule, PatrolLog, Incident, SOS
│           └── services/
│               ├── haversine_calculator.dart  # Kalkulator jarak Haversine & validasi geofence GPS (< 25m)
│               ├── qr_token_verifier.dart     # Verifikator QR bertanda waktu (HMAC/SHA256, anti titip absen)
│               ├── role_permissions.dart     # Matriks RBAC (Admin RT, Petugas Ronda, Warga)
│               ├── shift_swap_manager.dart    # State machine tukar giliran (Pending -> Accepted -> Approved)
│               ├── sos_event_dispatcher.dart  # Generator event darurat & payload FCM topic per RT
│               └── offline_sync_queue.dart    # Antrean lokal & rekonsiliasi saat patroli di blank spot
├── test/
│   └── ronda/
│       ├── haversine_test.dart                # Pengujian geofence & degradasi sinyal GPS
│       ├── qr_token_verifier_test.dart        # Pengujian token valid, kadaluarsa, palsu, dan salah pos
│       ├── role_permissions_test.dart         # Pengujian matriks wewenang peran
│       ├── shift_swap_manager_test.dart       # Pengujian alur tukar shift dan mutasi jadwal resmi
│       ├── sos_event_dispatcher_test.dart     # Pengujian pemicuan SOS, anti-spam debounce, dan payload FCM
│       └── offline_sync_queue_test.dart       # Pengujian antrean lokal dan pemulihan koneksi
└── harness/
    ├── seed_data.dart                         # Data fixture RT 04 Sukolilo (pengguna, 4 checkpoint nyata, jadwal)
    ├── mock_backend.dart                      # Server API in-memory (Auth, Check-in, Jadwal, SOS, Insiden)
    ├── run_simulation.dart                    # Runner simulasi interaktif skenario ronda 1 malam penuh
    └── verify.ps1                             # Script otomatisasi 1-klik untuk seluruh suite pengujian
```

---

## 2. Cara Menjalankan Harness

### 2.1 Jalankan Seluruh Verifikasi (1-Klik)
Dari direktori `Tugas-5`, jalankan script verifikasi PowerShell:
```powershell
powershell -ExecutionPolicy Bypass -File harness/verify.ps1
```
Script ini akan mengeksekusi:
1. Seluruh unit test otomatis (`flutter test test/ronda/`)
2. Skenario malam patroli lengkap (`dart run harness/run_simulation.dart`)
3. Pemeriksaan kualitas statis kode (`flutter analyze`)

### 2.2 Menjalankan Unit Test Saja
```powershell
flutter test test/ronda/
```
Output yang diharapkan:
```
00:02 +25: All tests passed!
```

### 2.3 Menjalankan Simulasi Malam Patroli Interaktif
Untuk melihat simulasi langkah demi langkah dari login petugas, scan pos ronda, pencegahan kecurangan jarak jauh, laporan insiden berfoto, hingga alarm darurat warga:
```powershell
dart run harness/run_simulation.dart
```

---

## 3. Matriks Skenario Pengujian pada Harness

| Skenario | Modul yang Diuji | Status Verifikasi |
| :--- | :--- | :---: |
| **Geofence Radius Pos** | Jarak $\le 25\text{ m}$ disetujui, $> 25\text{ m}$ ditolak | ✅ PASS |
| **Degradasi Sinyal GPS** | Penolakan check-in jika akurasi GPS $> 35\text{ m}$ (anti mock) | ✅ PASS |
| **Keaslian QR Code** | Validasi tanda tangan kriptografi SHA-256 + secret key | ✅ PASS |
| **Batas Waktu QR** | QR kedaluwarsa $> 180\text{ detik}$ otomatis ditolak | ✅ PASS |
| **Pencegahan Kecurangan** | Scan QR Pos 2 saat berada di Pos 1 ditolak geofence | ✅ PASS |
| **Otorisasi Peran (RBAC)** | Hanya Admin RT yang dapat mengesahkan pertukaran jadwal | ✅ PASS |
| **Alur Tukar Shift** | Request $\rightarrow$ Disetujui Calon $\rightarrow$ Disahkan Admin $\rightarrow$ Jadwal Bermutasi | ✅ PASS |
| **Alarm Darurat (SOS)** | Pembuatan payload FCM Topic `/topics/rt_..._emergency` dengan sirine | ✅ PASS |
| **Anti-Spam SOS** | Debounce window 15–30 detik mencegah banjir alarm | ✅ PASS |
| **Dukungan Offline-First** | Check-in saat tanpa sinyal disimpan lokal, otomatis tersinkron saat online | ✅ PASS |

---

## 4. Langkah Berikutnya untuk Implementasi UI
Dengan tersedianya harness ini, implementasi layar Flutter dapat dikerjakan dengan aman dan terukur:
1. Hubungkan modul scan kamera (`ImageService` / `mobile_scanner`) dengan `QrTokenVerifier` & `HaversineCalculator`.
2. Pasang `SosEventDispatcher` ke tombol darurat pada beranda warga.
3. Tampilkan antrean `OfflineSyncQueue` dengan indikator status sinkronisasi pada navbar.
