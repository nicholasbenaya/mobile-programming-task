
### Import Dataset Gist ke Supabase

Branch `feature/import-hero-dataset` menyediakan script `tool/import_hero_dataset.dart` agar dataset tidak perlu dimasukkan satu per satu. Script mengambil raw JSON Gist, membersihkan field yang tidak konsisten, mengubahnya ke schema tabel `heroes`, lalu mengunggah data secara batch. URL gambar dari field `img` disimpan dan ditampilkan sebagai network image oleh Flutter.

Jalankan setelah `01_schema.sql` sudah diterapkan. Gunakan **service role key hanya di terminal lokal**, bukan di source code atau aplikasi Flutter:

```powershell
cd Tugas-3
$env:SUPABASE_URL = "https://YOUR_PROJECT_ID.supabase.co"
$env:SUPABASE_SERVICE_ROLE_KEY = "YOUR_SERVICE_ROLE_KEY"
dart run tool/import_hero_dataset.dart
```

Script aman dijalankan ulang untuk tabel `heroes` dan kontribusi karena menggunakan upsert. Setelah import selesai, jalankan aplikasi dengan publishable key seperti biasa:

```powershell
flutter run -d chrome
```
# Aplikasi Informasi Pahlawan Nasional Indonesia

Aplikasi edukasi sejarah berbasis **Flutter** untuk mengenal dan mempelajari kisah keteladanan **Pahlawan Nasional Indonesia**. Dilengkapi dengan interface modern bernuansa kebangsaan.

---

## Anggota Pengembang

| No | Nama | NRP | Peran |
|:--:|:-----|:---:|:------|
| 1 | **Fito Dwi Ardiansah** | 5024241053 | Anggota Kelompok  |
| 2 | Nicholas Benaya | 5024241050 | Anggota Kelompok |
| 3 | Jordi | 5024241029 | Anggota Kelompok |
| 4 | Devi Putri Sekar Arum | 5024241049 | Anggota Kelompok |
| 5 | Muhamad Risqi Aditiya | 5024221010 | Anggota Kelompok |

---

## Pemenuhan Spesifikasi

| Spesifikasi | Status | Implementasi pada Aplikasi |
|:---|:---:|:---|
| **1. Terdapat list 15 nama pahlawan** | Selesai | 15 tokoh pahlawan terverifikasi dari berbagai pulau Nusantara |
| **2. Informasi lengkap per pahlawan** | Selesai | Foto offline, Daerah Asal lengkap, Biografi singkat & mendalam, Lifetime (tanggal & tempat lahir/wafat) |
| **3a. Mekanisme Dashboard** | Selesai | Banner *Jasmerah*, metrik statistik pahlawan/wilayah, Pahlawan Sorotan Hari Ini, jalan pintas menu |
| **3b. List nama pahlawan + icon Foto** | Selesai | Tampilan `ListView` dinamis dengan avatar foto pahlawan, badge daerah, masa hidup, dan tombol bookmark favorit |
| **3c. Klik list menampilkan detail lengkap** | Selesai | `HeroDetailScreen` dengan animasi transisi `Hero`, rincian masa hidup, rekam jejak perjuangan, dan kutipan inspiratif |
| **3d. Galeri foto pahlawan + nama, daerah, & lifetime** | Selesai | `HeroGalleryScreen` dengan tata letak grid responsif, kartu foto visual, badge daerah, masa hidup, dan dialog zoom interaktif |

---

## Daftar 15 Pahlawan Nasional

| No | Nama Pahlawan | Gelar / Julukan | Asal Daerah | Masa Hidup (Lifetime) | Era Perjuangan |
|:--:|:--------------|:----------------|:------------|:----------------------|:---------------|
| 1 | **Ir. Soekarno** | Bung Karno / Proklamator | Surabaya, Jawa Timur | 1901 – 1970 (Usia 69) | Kemerdekaan & Diplomasi |
| 2 | **Drs. Mohammad Hatta** | Bung Hatta / Bapak Koperasi | Bukittinggi, Sumatera Barat | 1902 – 1980 (Usia 77) | Kemerdekaan & Diplomasi |
| 3 | **Raden Adjeng Kartini** | Pelopor Emansipasi Wanita | Jepara, Jawa Tengah | 1879 – 1904 (Usia 25) | Pendidikan & Emansipasi |
| 4 | **Jenderal Besar Soedirman** | Panglima Besar TNI Pertama | Purbalingga, Jawa Tengah | 1916 – 1950 (Usia 34) | Revolusi Kemerdekaan |
| 5 | **Pangeran Diponegoro** | Pemimpin Perang Jawa | Yogyakarta, DI Yogyakarta | 1785 – 1855 (Usia 69) | Perlawanan Kerajaan / Daerah |
| 6 | **Ki Hajar Dewantara** | Bapak Pendidikan Nasional | Yogyakarta, DI Yogyakarta | 1889 – 1959 (Usia 69) | Pendidikan & Emansipasi |
| 7 | **Cut Nyak Dhien** | Srikandi Perang Aceh | Lampadang, Aceh | 1848 – 1908 (Usia 60) | Perlawanan Kerajaan / Daerah |
| 8 | **Kapitan Pattimura** | Thomas Matulessy / Kapitan Maluku | Saparua, Maluku | 1783 – 1817 (Usia 34) | Perlawanan Kerajaan / Daerah |
| 9 | **Sultan Hasanuddin** | Ayam Jantan dari Timur | Gowa, Sulawesi Selatan | 1631 – 1670 (Usia 39) | Perlawanan Kerajaan / Daerah |
| 10 | **Tuanku Imam Bonjol** | Pemimpin Perang Padri | Pasaman, Sumatera Barat | 1772 – 1864 (Usia 92) | Perlawanan Kerajaan / Daerah |
| 11 | **I Gusti Ngurah Rai** | Komandan Ciung Wanara | Badung, Bali | 1917 – 1946 (Usia 29) | Revolusi Kemerdekaan |
| 12 | **Frans Kaisiepo** | Tokoh Integrasi Papua ke NKRI | Biak, Papua | 1921 – 1979 (Usia 57) | Kemerdekaan & Diplomasi |
| 13 | **Bung Tomo (Sutomo)** | Pembakar Semangat 10 November | Surabaya, Jawa Timur | 1920 – 1981 (Usia 61) | Revolusi Kemerdekaan |
| 14 | **Raden Dewi Sartika** | Perintis Sakola Istri | Bandung, Jawa Barat | 1884 – 1947 (Usia 62) | Pendidikan & Emansipasi |
| 15 | **K.H. Ahmad Dahlan** | Pendiri Persyarikatan Muhammadiyah | Yogyakarta, DI Yogyakarta | 1868 – 1923 (Usia 54) | Pendidikan & Emansipasi |

---

## Struktur Folder 

Menggunakan arsitektur modular **MVC (Model - View - Controller)** dengan **Provider** sebagai *State Management*:

```text
Pahlawan Nasional/
├── assets/
│   └── images/                     # 15 foto pahlawan nasional (offline assets)
├── supabase/
│   ├── 01_schema.sql               # Membuat tabel + Row Level Security
│   └── 02_seed_data.sql            # Data awal 15 pahlawan & 10 soal kuis
├── lib/
│   ├── main.dart                   # Entry point aplikasi & Provider configuration
│   ├── models/
│   │   ├── hero_model.dart         # Struktur model data pahlawan nasional
│   │   └── quiz_model.dart         # Struktur model kuis edukasi
│   ├── config/
│   │   └── supabase_config.dart    # URL & publishable key project Supabase
│   ├── services/
│   │   └── supabase_service.dart   # Inisialisasi Supabase & login tamu (anonymous)
│   ├── repositories/
│   │   ├── hero_repository.dart    # Panggilan API pahlawan & favorit
│   │   └── quiz_repository.dart    # Panggilan API soal kuis
│   ├── controllers/
│   │   └── pahlawan_controller.dart# State management pencarian, filter, favorit, statistik
│   ├── utils/
│   │   └── app_theme.dart          # Tema Material 3 nuansa kebangsaan Indonesia
│   └── views/
│       ├── widgets/
│       │   ├── hero_card.dart          # Widget item list pahlawan dengan avatar & badge
│       │   ├── gallery_card.dart       # Widget kartu foto galeri pahlawan
│       │   ├── stat_card.dart          # Widget statistik dashboard
│       │   ├── search_filter_bar.dart  # Bar pencarian instan dan filter wilayah
│       │   └── hero_photo_dialog.dart  # Modal dialog zoom foto interaktif
│       └── screens/
│           ├── main_navigation_screen.dart # Bottom navigation bar
│           ├── dashboard_screen.dart       # Dashboard utama aplikasi
│           ├── hero_list_screen.dart       # Layar daftar 15 pahlawan (List View)
│           ├── hero_detail_screen.dart     # Layar rincian lengkap pahlawan (Detail View)
│           ├── hero_gallery_screen.dart    # Layar galeri visual pahlawan (Gallery View)
│           └── hero_quiz_screen.dart       # Layar kuis wawasan sejarah interaktif
├── test/
│   └── widget_test.dart            # Smoke test & automated testing
├── pubspec.yaml                    # Manajemen paket dan deklarasi aset
└── README.md                       # Dokumentasi lengkap proyek
```

---

## Panduan Menjalankan Aplikasi

### Prasyarat
- [Flutter SDK](https://docs.flutter.dev/) versi `>=3.0.0`
- Perangkat / Emulator Android, Browser Google Chrome / Edge, atau Windows Desktop

### Langkah Menjalankan

1. Buka terminal dan masuk ke direktori proyek:
   ```bash
   cd Tugas-3
   ```

2. Ambil dependensi paket:
   ```bash
   flutter pub get
   ```

   Pastikan `lib/config/supabase_config.dart` sudah diisi URL & key project Supabase.

3. Jalankan aplikasi di browser Chrome:
   ```bash
   flutter run -d chrome
   ```

4. Atau jalankan di Windows Desktop:
   ```bash
   flutter run -d windows
   ```

---

## Database & API (Supabase)

Data disimpan di **Supabase (PostgreSQL online)** dan diakses lewat **REST API** yang dibuat otomatis oleh Supabase.
Keamanan diatur dengan **Row Level Security**: data pahlawan & kuis hanya bisa dibaca, favorit hanya bisa diakses oleh pemiliknya (login tamu/anonymous).

| Tabel | Isi | Akses dari aplikasi |
|:--|:--|:--|
| `heroes` | Data utama 15 pahlawan | Baca |
| `hero_contributions` | Jasa/kontribusi tiap pahlawan | Baca |
| `quiz_questions` | 10 soal kuis | Baca |
| `quiz_options` | Pilihan jawaban tiap soal | Baca |
| `favorites` | Favorit per pengguna | Baca, tambah, hapus (milik sendiri) |

### Menyiapkan Server Database Supabase

Tugas-3 menggunakan **Supabase Cloud**, sehingga server database tidak dijalankan dengan `flutter run` dan tidak perlu dijalankan dari folder repository. Folder `supabase/` hanya berisi SQL untuk membuat dan mengisi database pada project Supabase.

1. Buka [supabase.com](https://supabase.com), buat akun, lalu buat project baru.
2. Tunggu sampai project selesai dibuat.
3. Buka menu **SQL Editor**, jalankan isi `supabase/01_schema.sql` terlebih dahulu.
4. Jalankan isi `supabase/02_seed_data.sql` setelah schema berhasil dibuat.
5. Buka **Authentication > Providers**, aktifkan **Anonymous Sign-Ins**.
6. Buka **Project Settings > API**, salin **Project URL** dan **Publishable key**.

Jalankan aplikasi dari root repository dengan environment variable berikut. Nilai ini diteruskan saat compile dan tidak perlu ditulis ke source code:

PowerShell:

```powershell
cd Tugas-3
flutter pub get
flutter run -d chrome `
   --dart-define=SUPABASE_URL=https://YOUR_PROJECT_ID.supabase.co `
   --dart-define=SUPABASE_KEY=YOUR_PUBLISHABLE_KEY
```

Windows Desktop:

```powershell
cd Tugas-3
flutter run -d windows `
   --dart-define=SUPABASE_URL=https://YOUR_PROJECT_ID.supabase.co `
   --dart-define=SUPABASE_KEY=YOUR_PUBLISHABLE_KEY
```

Alternatifnya, isi nilai URL dan key pada `lib/config/supabase_config.dart`. Jangan memasukkan `service_role` key ke aplikasi Flutter; gunakan hanya Project URL dan Publishable/anon key.

### Menjalankan dan Menguji Tugas-3

Dari root repository:

```powershell
cd Tugas-3
flutter pub get
flutter analyze
flutter test
```

Jika aplikasi menampilkan error pemuatan data, periksa URL/key, pastikan kedua file SQL sudah dijalankan, dan pastikan **Anonymous Sign-Ins** aktif. Jika tabel kosong, jalankan ulang `supabase/02_seed_data.sql` setelah memastikan schema sudah tersedia.
