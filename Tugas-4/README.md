# SensorLog

Aplikasi catatan lapangan berbasis **Flutter** dan **Supabase**. Setiap akun menyimpan foto dari kamera, lokasi GPS, dan data sensor perangkat (kompas, kemiringan, baterai), dan hanya pemilik akun yang bisa mengaksesnya.

## Fitur

- **Akun**: daftar dan masuk dengan email + password, atau **masuk dengan Google**
- **Data privat per akun**: setiap akun hanya bisa melihat, mengubah, dan menghapus catatan serta fotonya sendiri
- Ambil foto dari kamera (atau pilih dari galeri)
- Catat lokasi GPS otomatis (latitude, longitude, akurasi)
- Sensor tambahan: kompas, kemiringan, level baterai
- Foto disimpan di Supabase Storage (bucket privat), lokasi file foto (`photo_path`) dan koordinat disimpan di tabel database
- Daftar catatan dengan pencarian, filter kategori, dan statistik
- Peta semua catatan (OpenStreetMap, tanpa API key)
- Halaman detail dan halaman akun (profil, keluar)
- Ekspor catatan ke CSV, mode terang dan gelap
- Animasi dan transisi: perpindahan layar, efek tekan tombol, skeleton loading, daftar muncul berurutan, animasi sukses saat simpan (menghormati pengaturan "kurangi animasi" perangkat)

## Kesesuaian dengan spesifikasi tugas

| # | Spesifikasi | Implementasi |
|---|---|---|
| 1 | Mencatat lokasi dari GPS | `data/services/location_service.dart`; kolom `latitude`, `longitude`, `accuracy` |
| 2 | Menyimpan data dari kamera | `data/services/image_service.dart` (`ImageSource.camera`); foto diunggah ke bucket `record-photos` |
| 3 | Lokasi dan gambar (lokasi file di folder server) disimpan ke database | Kolom `photo_path` berisi path file di storage (`<user_id>/<uuid>.jpg`), satu baris dengan koordinat di tabel `records` |
| 4 | Model aplikasi bebas | Jurnal observasi lapangan dengan akun pengguna |
| 5 | Sensor tambahan (opsional) | Kompas, kemiringan, baterai (`data/services/sensor_service.dart`) |

## Struktur folder

```
lib/
├── main.dart                     # titik masuk, menangkap error startup
├── app.dart                      # MaterialApp + dependency injection (Provider)
├── core/
│   ├── config/
│   │   ├── secrets.dart          # URL & anon key Supabase (diisi manual, di-gitignore)
│   │   ├── secrets.example.dart  # template kosong
│   │   └── env.dart              # membaca dan membersihkan nilai dari secrets.dart
│   ├── constants/                # batas ukuran, URL tile peta, deep link login
│   ├── errors/                   # AppException
│   ├── theme/                    # warna dan ThemeData
│   └── utils/                    # formatters, validators
├── data/
│   ├── models/                   # RecordModel, RecordDraft, RecordCategory
│   ├── services/                 # supabase, lokasi, sensor, kamera, ekspor CSV
│   └── repositories/
│       ├── auth_repository.dart  # daftar, masuk, Google, keluar
│       └── record_repository.dart# database + storage (signed URL)
├── providers/
│   ├── auth_provider.dart        # sesi pengguna & status login
│   ├── records_provider.dart     # daftar catatan (otomatis ikut akun aktif)
│   └── capture_provider.dart     # form catatan baru + sensor langsung
└── presentation/
    ├── navigation/               # AuthGate, MainShell (tab), AppRoutes
    ├── screens/
    │   ├── auth/                 # login + daftar (+ widgets/)
    │   ├── account/              # profil dan keluar
    │   ├── home/  capture/  map/  detail/  setup/
    └── widgets/                  # komponen yang dipakai ulang (motion/ = animasi)
supabase/schema.sql               # tabel, RLS, dan bucket storage
```

Alurnya satu arah: `presentation` → `providers` → `data`. Layar tidak pernah memanggil Supabase langsung.

## Animasi dan transisi

| Elemen | Efek |
|---|---|
| Pindah layar (`navigation/app_transitions.dart`) | Fade + geser; layar Catat naik dari bawah |
| Tab Beranda/Peta | Fade + geser sesuai arah, indikator tab berbentuk pil yang beranimasi |
| Semua tombol utama (`widgets/motion/press_scale.dart`) | Mengecil saat ditekan + getar halus |
| Tombol Masuk/Simpan (`loading_button.dart`) | Label berganti jadi indikator loading dengan transisi |
| Memuat daftar (`shimmer_skeleton.dart`) | Kerangka kartu berkilau, bukan spinner kosong |
| Daftar catatan, detail, akun | Muncul berurutan (fade + geser) |
| Foto (`widgets/network_photo.dart`) | Fade-in saat termuat; Hero dari daftar ke detail |
| Kartu statistik | Angka menghitung naik |
| Layar Catat | Foto, status GPS, dan jarum kompas berganti dengan halus; centang "Tersimpan!" setelah berhasil |
| Login | Logo dan banner pesan beranimasi; ikon mata password berganti halus |
| Peta | Pin muncul membal satu per satu |
| Hapus catatan | Pemuat modal selama proses berjalan |

Animasi berada di `lib/presentation/widgets/motion/`. Jika pengguna mengaktifkan "kurangi animasi" di perangkat, efek masuk dilewati.

## Cara kerja akun dan privasi

- `AuthGate` memantau sesi: belum masuk → layar Masuk/Daftar, sudah masuk → aplikasi.
- Kolom `records.user_id` otomatis berisi `auth.uid()` dan **RLS** hanya mengizinkan baris milik akun itu.
- Foto berada di folder bernama user id (`<user_id>/<uuid>.jpg`). Bucket **privat**, policy storage hanya mengizinkan pemilik folder, dan foto ditampilkan lewat *signed URL* sementara (berlaku 6 jam; tarik layar ke bawah untuk menyegarkan).
- Saat keluar atau ganti akun, daftar catatan di memori dikosongkan dan dimuat ulang untuk akun baru.

## Persiapan

### 1. Supabase: database dan storage

1. Buat proyek di [supabase.com](https://supabase.com).
2. Buka **SQL Editor**, jalankan isi `supabase/schema.sql` (aman dijalankan berulang kali).
3. Buka **Authentication → Sign In / Providers**, pastikan **Email** aktif.
4. (Opsional, memudahkan demo) Di **Email**, matikan **Confirm email** agar akun baru langsung bisa masuk. Jika dibiarkan aktif, pengguna harus klik tautan verifikasi di email dulu; aplikasi sudah menampilkan pesannya.

### 2. Supabase: Redirect URL

Buka **Authentication → URL Configuration → Redirect URLs**, tambahkan:

```
io.supabase.sensorlog://login-callback/
```

Untuk menjalankan di web, tambahkan juga alamat lokal Anda (mis. `http://localhost:xxxx`) dan atur **Site URL** sesuai.

### 3. Login Google

1. Buka [Google Cloud Console](https://console.cloud.google.com) → **APIs & Services → Credentials → Create Credentials → OAuth client ID**.
   Jika diminta, atur dulu **OAuth consent screen** (External, isi nama aplikasi dan email).
2. Application type: **Web application**.
3. Pada **Authorized redirect URIs** isi:
   `https://<project-ref>.supabase.co/auth/v1/callback`
   (alamat persisnya ada di Supabase: **Authentication → Providers → Google**).
4. Salin **Client ID** dan **Client secret**.
5. Di Supabase: **Authentication → Providers → Google**, nyalakan, tempel Client ID dan Client secret, lalu **Save**.

Jika aplikasi Google masih berstatus *Testing*, tambahkan email Anda di **OAuth consent screen → Test users**.

### 4. Isi kunci Supabase di aplikasi

Buka `lib/core/config/secrets.dart`:

```dart
class Secrets {
  const Secrets._();

  static const supabaseUrl = 'https://xxxxxxxx.supabase.co';
  static const supabaseAnonKey = 'eyJ...';
}
```

Keduanya ada di **Project Settings → API**. `supabaseUrl` hanya domain proyek (tanpa `/rest/v1`). Pakai key **anon public**, bukan `service_role`.

### 5. Platform dan izin

Jika folder `android/` dan `ios/` belum ada:

```
flutter create . --org id.sensorlog --project-name sensorlog_app
```

**Android**: `android/app/src/main/AndroidManifest.xml`

Di dalam `<manifest>`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.CAMERA"/>
```

Di dalam `<activity android:name=".MainActivity" ...>` (untuk kembali ke aplikasi setelah login Google):

```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="io.supabase.sensorlog" android:host="login-callback" />
</intent-filter>
```

**iOS**: `ios/Runner/Info.plist`

```xml
<key>NSLocationWhenInUseUsageDescription</key><string>Untuk mencatat lokasi temuan.</string>
<key>NSCameraUsageDescription</key><string>Untuk memotret temuan.</string>
<key>NSPhotoLibraryUsageDescription</key><string>Untuk memilih foto temuan.</string>
<key>NSMotionUsageDescription</key><string>Untuk membaca kemiringan perangkat.</string>
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array><string>io.supabase.sensorlog</string></array>
  </dict>
</array>
```

### 6. Jalankan

```
flutter pub get
flutter devices
flutter run -d <id perangkat>
```

Kebutuhan: Flutter 3.27 atau lebih baru.

## Cara memakai

1. Buka aplikasi, pilih **Daftar** (atau **Lanjutkan dengan Google**).
2. Ketuk tombol kamera di tengah bawah, ambil foto, tunggu GPS terkunci, isi judul dan kategori, lalu **Simpan catatan**.
3. Lihat hasilnya di **Beranda**, **Peta**, atau detail. Ketuk foto profil di pojok kanan atas untuk membuka **Akun** dan **Keluar**.

## Memeriksa data di Supabase (untuk demo)

- **Authentication → Users**: daftar akun terdaftar.
- **Table Editor → records**: baris berisi `user_id`, koordinat, data sensor, dan `photo_path`.
- **Storage → record-photos**: file foto berada di folder bernama user id.
- Uji isolasi: daftar dua akun berbeda, buat catatan di masing-masing, dan pastikan tidak saling terlihat.

## Pemecahan masalah

| Gejala | Penyebab dan solusi |
|---|---|
| `Target of URI doesn't exist: 'package:provider/provider.dart'` | Jalankan `flutter pub get`, lalu restart Dart analysis server |
| `intl ^0.20.3 is required` | Di `pubspec.yaml` ubah menjadi `intl: ^0.20.3` |
| Layar kosong/putih saja (terutama di APK) | Izin `INTERNET` belum ada di `AndroidManifest.xml` utama, atau error tampilan. Versi terbaru menampilkan pesan error di layar; kirim teksnya. Untuk log lengkap: `flutter run --release` dengan HP tersambung kabel |
| Layar "Supabase belum dikonfigurasi" | `secrets.dart` masih berisi placeholder |
| 404 `Invalid path specified in request URL` | `supabaseUrl` salah; gunakan `https://<ref>.supabase.co` |
| "Email atau password salah" | Kredensial salah, atau akun dibuat via Google (masuk dengan tombol Google) |
| "Email belum diverifikasi" | Klik tautan di email, atau matikan **Confirm email** di Supabase |
| "Login Google belum diaktifkan di Supabase" | Aktifkan provider Google dan isi Client ID/secret |
| Google: `redirect_uri_mismatch` | Redirect URI di Google Cloud harus persis `https://<ref>.supabase.co/auth/v1/callback` |
| Setelah login Google tidak kembali ke aplikasi | Redirect URL `io.supabase.sensorlog://login-callback/` belum didaftarkan di Supabase, atau intent-filter/Info.plist belum ditambahkan |
| Daftar catatan gagal dimuat | `schema.sql` belum dijalankan (tabel atau bucket belum ada) |
| Foto tidak tampil | Bucket/policy belum sesuai; jalankan ulang `schema.sql`. Foto lama dari versi anonim milik akun anonim dan tidak terlihat oleh akun baru |
| Lokasi tidak muncul | Nyalakan GPS dan izinkan akses lokasi; coba di area terbuka |

### Catatan tentang web

Pengambilan foto, ekspor CSV, dan kompas memakai fitur yang hanya tersedia di HP, jadi aplikasi belum mendukung Flutter web sepenuhnya. Login email dan Google bisa dicoba di web, tetapi gunakan emulator atau perangkat Android/iOS untuk fitur lengkap.

## Keamanan

- Anon key memang dirancang berada di sisi klien dan dilindungi oleh RLS. Jangan pernah memakai `service_role` key di aplikasi.
- `secrets.dart` ada di `.gitignore`.
- Batas input dijaga di aplikasi dan di database lewat `check` constraint (judul 1–100 karakter, catatan maks. 1000, foto maks. 8 MB, rentang koordinat dan sensor).

## Menambah fitur

- **Kategori baru**: `data/models/record_category.dart`, `presentation/widgets/category_style.dart`, dan `check` kategori di `schema.sql`.
- **Kolom baru**: `schema.sql` → `RecordModel` / `RecordDraft` → UI.
- **Lupa password**: butuh layar untuk menetapkan password baru dari tautan pemulihan.
- **Antrean offline**: tambahkan di `RecordRepository`.
