# SensorLog (Flutter + Supabase)

Aplikasi catatan lapangan: foto, GPS, kompas, kemiringan, dan baterai tersimpan ke Supabase.

## Struktur folder

```
lib/
├── main.dart                  # titik masuk
├── app.dart                   # MaterialApp + DI (Provider)
├── core/                      # hal umum, tanpa logika bisnis
│   ├── config/env.dart        # SUPABASE_URL & ANON_KEY (dart-define)
│   ├── constants/             # batas ukuran, URL tile peta
│   ├── errors/                # AppException
│   ├── theme/                 # warna & ThemeData
│   └── utils/                 # formatters, validators
├── data/                      # semua akses data / perangkat
│   ├── models/                # RecordModel, RecordDraft, RecordCategory
│   ├── services/              # supabase, lokasi, sensor, kamera, ekspor CSV
│   └── repositories/          # RecordRepository (satu-satunya yang bicara ke Supabase)
├── providers/                 # state (ChangeNotifier)
│   ├── records_provider.dart  # daftar, cari, filter, hapus
│   └── capture_provider.dart  # form catatan baru + sensor langsung
└── presentation/              # UI saja
    ├── navigation/            # MainShell (tab), AppRoutes
    ├── screens/               # home, capture, map, detail, setup
    └── widgets/               # komponen yang dipakai ulang
supabase/schema.sql            # tabel, RLS, bucket storage
```

Aturan sederhana: `presentation` → `providers` → `data`. UI tidak pernah memanggil Supabase langsung.

## Setup

1. Buat project di Supabase, lalu jalankan `supabase/schema.sql` di SQL Editor.
2. Aktifkan **Authentication → Providers → Allow anonymous sign-ins**.
3. Buat platform folder: `flutter create . --org id.sensorlog --project-name sensorlog_app`
4. Tambahkan izin (di bawah), lalu:

```
flutter pub get
flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
```

Butuh Flutter 3.27+.

## Izin

**Android** — `android/app/src/main/AndroidManifest.xml`, di dalam `<manifest>`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.CAMERA"/>
```

**iOS** — `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key><string>Untuk mencatat lokasi temuan.</string>
<key>NSCameraUsageDescription</key><string>Untuk memotret temuan.</string>
<key>NSPhotoLibraryUsageDescription</key><string>Untuk memilih foto temuan.</string>
<key>NSMotionUsageDescription</key><string>Untuk membaca kemiringan perangkat.</string>
```

## Menambah fitur

- Kategori baru: tambah di `data/models/record_category.dart`, warna/ikon di `presentation/widgets/category_style.dart`, dan update `check` di `schema.sql`.
- Kolom baru: `schema.sql` → `RecordModel` / `RecordDraft` → UI.
