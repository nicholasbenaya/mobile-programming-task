# SensorLog

Aplikasi catatan lapangan berbasis **Flutter** dan **Supabase**. Setiap catatan menyimpan foto dari kamera, lokasi GPS, dan data sensor perangkat (kompas, kemiringan, baterai).

## Fitur

- Ambil foto dari kamera (atau pilih dari galeri)
- Catat lokasi GPS otomatis (latitude, longitude, akurasi)
- Sensor tambahan: kompas, kemiringan, level baterai
- Foto disimpan di Supabase Storage, sedangkan lokasi file foto (`photo_path`) dan koordinat disimpan di tabel database
- Daftar catatan dengan pencarian, filter kategori, dan statistik
- Peta semua catatan (OpenStreetMap, tanpa API key)
- Halaman detail: foto, data sensor, peta mini, lokasi file di server, hapus catatan
- Ekspor semua catatan ke CSV
- Mode terang dan gelap

## Kesesuaian dengan spesifikasi tugas

| # | Spesifikasi | Implementasi |
|---|---|---|
| 1 | Mencatat lokasi dari GPS | `data/services/location_service.dart`; koordinat disimpan di kolom `latitude`, `longitude`, `accuracy` |
| 2 | Menyimpan data dari kamera | `data/services/image_service.dart` (`ImageSource.camera`); foto diunggah ke bucket `record-photos` |
| 3 | Lokasi dan gambar (lokasi file di folder server) disimpan ke database | Kolom `photo_path` berisi path file di storage (`<user_id>/<uuid>.jpg`), bersama koordinat dalam satu baris tabel `records` |
| 4 | Model aplikasi bebas | Jurnal observasi lapangan |
| 5 | Sensor tambahan (opsional) | Kompas, kemiringan, baterai (`data/services/sensor_service.dart`) |

## Struktur folder

```
lib/
├── main.dart                     # titik masuk, menangkap error startup
├── app.dart                      # MaterialApp + dependency injection (Provider)
├── core/                         # hal umum, tanpa logika bisnis
│   ├── config/
│   │   ├── secrets.dart          # URL & anon key Supabase (diisi manual, di-gitignore)
│   │   ├── secrets.example.dart  # template kosong
│   │   └── env.dart              # membaca dan membersihkan nilai dari secrets.dart
│   ├── constants/                # batas ukuran, URL tile peta
│   ├── errors/                   # AppException
│   ├── theme/                    # warna dan ThemeData
│   └── utils/                    # formatters, validators
├── data/                         # semua akses data dan perangkat
│   ├── models/                   # RecordModel, RecordDraft, RecordCategory
│   ├── services/                 # supabase, lokasi, sensor, kamera, ekspor CSV
│   └── repositories/             # RecordRepository (satu-satunya yang bicara ke Supabase)
├── providers/                    # state (ChangeNotifier)
│   ├── records_provider.dart     # daftar, cari, filter, hapus
│   └── capture_provider.dart     # form catatan baru + sensor langsung
└── presentation/                 # UI saja
    ├── navigation/               # MainShell (tab), AppRoutes
    ├── screens/
    │   ├── home/
    │   ├── capture/              # + widgets/ (photo, sensor, detail form)
    │   ├── map/
    │   ├── detail/
    │   └── setup/                # layar error konfigurasi/koneksi
    └── widgets/                  # komponen yang dipakai ulang
supabase/schema.sql               # tabel, RLS, dan bucket storage
```

Aturan alurnya satu arah: `presentation` → `providers` → `data`. Layar tidak pernah memanggil Supabase langsung, jadi mengganti backend cukup mengubah `RecordRepository`.

## Persiapan

### 1. Supabase

1. Buat proyek di [supabase.com](https://supabase.com).
2. Buka **SQL Editor**, jalankan isi `supabase/schema.sql`. Skrip ini membuat tabel `records`, kebijakan RLS, bucket `record-photos`, dan kebijakan storage. Aman dijalankan berulang kali.
3. Buka **Authentication → Sign In / Providers**, nyalakan **Allow anonymous sign-ins**, lalu **Save**.

### 2. Isi kunci Supabase

Buka `lib/core/config/secrets.dart`:

```dart
class Secrets {
  const Secrets._();

  static const supabaseUrl = 'https://xxxxxxxx.supabase.co';
  static const supabaseAnonKey = 'eyJ...';
}
```

Keduanya ada di **Project Settings → API**.

- `supabaseUrl` hanya domain proyek, tanpa `/rest/v1` atau path lain.
- Pakai key **anon public**, bukan `service_role`.
- `secrets.dart` sudah masuk `.gitignore` agar tidak ikut ter-commit.

### 3. Platform dan izin

Jika folder `android/` dan `ios/` belum ada, buat dengan:

```
flutter create . --org id.sensorlog --project-name sensorlog_app
```

**Android**: di `android/app/src/main/AndroidManifest.xml`, di dalam `<manifest>`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.CAMERA"/>
```

**iOS**: di `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key><string>Untuk mencatat lokasi temuan.</string>
<key>NSCameraUsageDescription</key><string>Untuk memotret temuan.</string>
<key>NSPhotoLibraryUsageDescription</key><string>Untuk memilih foto temuan.</string>
<key>NSMotionUsageDescription</key><string>Untuk membaca kemiringan perangkat.</string>
```

### 4. Jalankan

```
flutter pub get
flutter devices
flutter run -d <id perangkat>
```

Kebutuhan: Flutter 3.27 atau lebih baru. Aplikasi ini dirancang untuk **HP (Android/iOS)**.

## Cara memakai

1. Ketuk tombol kamera di tengah bawah.
2. Ambil foto, tunggu lokasi GPS terkunci (akurasi tampil di kartu lokasi), lalu isi judul dan kategori.
3. Ketuk **Simpan catatan**.
4. Lihat hasilnya di **Beranda**, **Peta**, atau halaman detail.

## Memeriksa data di Supabase (untuk demo)

- **Table Editor → records**: setiap baris berisi koordinat, data sensor, dan `photo_path`.
- **Storage → record-photos**: file foto berada di folder bernama user id, sesuai `photo_path`.

## Pemecahan masalah

| Gejala | Penyebab dan solusi |
|---|---|
| `Target of URI doesn't exist: 'package:provider/provider.dart'` | Paket belum terpasang. Jalankan `flutter pub get`, lalu restart Dart analysis server |
| `intl ^0.20.3 is required` saat `pub get` | Di `pubspec.yaml`, ubah menjadi `intl: ^0.20.3` |
| Layar "Supabase belum dikonfigurasi" | `secrets.dart` masih berisi placeholder. Isi URL dan anon key |
| 404 `Invalid path specified in request URL` | `supabaseUrl` mengandung path tambahan atau salah ketik. Gunakan `https://<ref>.supabase.co` |
| 422 `anonymous_provider_disabled` | Aktifkan **Allow anonymous sign-ins** di Authentication |
| Daftar catatan gagal dimuat setelah login berhasil | `schema.sql` belum dijalankan (tabel atau bucket belum ada) |
| Lokasi tidak muncul | Nyalakan GPS dan izinkan akses lokasi; coba di area terbuka lalu tekan tombol segarkan |
| Kompas bernilai `—` | Perangkat tidak punya sensor magnetometer, atau berjalan di browser |

### Catatan tentang web

Aplikasi ini belum mendukung Flutter web sepenuhnya. Pengambilan foto, ekspor CSV, dan kompas memakai fitur yang hanya tersedia di HP. Gunakan emulator atau perangkat Android/iOS.

## Keamanan

- Data dipisahkan per perangkat lewat login anonim dan RLS: pengguna hanya bisa membaca dan mengubah catatannya sendiri.
- Anon key memang dirancang untuk berada di sisi klien dan dilindungi oleh RLS. Jangan pernah memakai `service_role` key di aplikasi.
- Bucket `record-photos` bersifat publik untuk dibaca. Path-nya memakai UUID yang sulit ditebak. Untuk foto sensitif, ubah bucket menjadi privat dan gunakan signed URL.
- Batas input dijaga di dua lapis: validasi di aplikasi dan `check` constraint di database (judul 1–100 karakter, catatan maks. 1000, foto maks. 8 MB, rentang koordinat dan sensor).

## Menambah fitur

- **Kategori baru**: tambahkan di `data/models/record_category.dart`, atur warna dan ikon di `presentation/widgets/category_style.dart`, lalu ubah `check` kategori di `schema.sql`.
- **Kolom baru**: ubah `schema.sql`, lalu `RecordModel` dan `RecordDraft`, lalu UI.
- **Antrean offline**: tambahkan di `RecordRepository` agar layar tidak perlu diubah.