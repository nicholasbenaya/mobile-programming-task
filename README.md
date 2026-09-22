# Mobile Programming Task

Repository ini berisi kumpulan tugas pemrograman mobile. Setiap tugas dibuat sebagai proyek Flutter mandiri, sehingga source code, asset, dependency, dan konfigurasi masing-masing tugas tidak saling berbagi.

## Anggota Kelompok

| No | Nama | NRP |
|----|------|-----|
| 1  | Nicholas Benaya | 5024241050 |
| 2  | Jordi | 5024241029 |
| 3  | Devi Putri Sekar Arum | 5024241049 |
| 4  | Fito Dwi Ardiansah | 5024241053 |
| 5  | Muhamad Risqi Aditiya | 5024221010 |

## Panduan Membaca Repository

README di root ini berisi informasi umum repository dan anggota kelompok. Setiap folder tugas memiliki nested README yang berfungsi sebagai laporan resmi untuk project tersebut.

Assessor dapat merujuk ke nested README di dalam folder tugas untuk melihat tujuan, fitur, struktur kode, dependency, instruksi menjalankan, dan informasi teknis project secara lengkap. Dengan demikian, informasi anggota kelompok cukup dipelihara di README root dan tidak perlu diulang pada setiap laporan project.

## Prasyarat

- Flutter SDK terpasang dan dapat dijalankan dari terminal.
- Dart SDK mengikuti versi yang disertakan oleh Flutter.
- Device atau browser yang mendukung Flutter.

Cek instalasi Flutter dengan:

```bash
flutter doctor
```

## Setelah Clone

Clone repository lalu masuk ke folder repository:

```bash
git clone https://github.com/nicholasbenaya/mobile-programming-task.git
cd mobile-programming-task
```

Setiap tugas memiliki folder sendiri. Jalankan perintah Flutter dari folder tugas yang ingin digunakan.

## How to Contribute

### 1. Siapkan Repository

Pastikan branch lokal sudah menggunakan versi terbaru dari `main`:

```bash
git switch main
git pull origin main
```

### 2. Buat Branch Fitur

Buat branch baru untuk setiap perubahan. Gunakan nama yang singkat dan deskriptif:

```bash
git switch -c feature/nama-fitur
```

Contoh prefix branch:

- `feature/` untuk fitur baru
- `fix/` untuk perbaikan bug
- `docs/` untuk dokumentasi
- `polishing/` untuk penyempurnaan tampilan atau interaksi

Jangan mengerjakan perubahan langsung di branch `main`.

### 3. Kerjakan Perubahan

- Ikuti struktur folder dan pola kode dari tugas yang sedang dikerjakan.
- Jalankan perintah dari folder tugas terkait, misalnya `Tugas-2`.
- Jangan menyertakan file hasil build, konfigurasi lokal, atau perubahan yang tidak berkaitan.
- Gunakan pesan commit yang singkat dan menjelaskan perubahan.

Contoh:

```bash
cd Tugas-2
flutter pub get
flutter analyze
flutter test
```

### 4. Commit dan Push

Kembali ke root repository jika diperlukan, lalu commit perubahan pada branch fitur:

```bash
git add path/ke/file
git commit -m "Add descriptive change"
git push -u origin feature/nama-fitur
```

### 5. Buat Pull Request

Buat Pull Request dari branch fitur ke `main` dengan informasi berikut:

- Ringkasan perubahan.
- Alasan perubahan diperlukan.
- Cara menguji perubahan.
- Screenshot atau video jika perubahan memengaruhi tampilan.
- Catatan tentang hal yang belum selesai atau perlu diperhatikan.

Sebelum meminta review, pastikan branch sudah diperbarui dari `main` dan semua pemeriksaan yang relevan berhasil:

```bash
git switch feature/nama-fitur
git fetch origin
git merge origin/main
flutter analyze
flutter test
```

Setelah Pull Request selesai di-merge, hapus branch fitur lokal dan remote jika sudah tidak diperlukan:

```bash
git switch main
git pull origin main
git branch -d feature/nama-fitur
git push origin --delete feature/nama-fitur
```

## Menjalankan Tugas 1

Tugas 1 adalah aplikasi skor pertandingan 2 pemain.

```bash
cd Tugas-1
flutter pub get
flutter run
```

Untuk menjalankan Tugas 1 di browser Chrome:

```bash
flutter run -d chrome
```

Untuk kembali ke root repository setelah selesai:

```bash
cd ..
```

Laporan project dan dokumentasi khusus aplikasi skor tersedia di [`Tugas-1/README.md`](Tugas-1/README.md).

## Struktur Repository

```text
.
├── Tugas-1/
│   ├── assets/       # Asset khusus Tugas-1
│   ├── lib/          # Source code Tugas-1
│   ├── web/          # Konfigurasi Flutter Web Tugas-1
│   ├── pubspec.yaml  # Dependency dan konfigurasi Tugas-1
│   └── README.md     # Dokumentasi detail Tugas-1
└── README.md         # Panduan umum repository
```

## Menambahkan Tugas Berikutnya

Buat setiap tugas sebagai folder Flutter terpisah, misalnya:

```text
Tugas-2/
├── assets/
├── lib/
├── pubspec.yaml
└── README.md
```

Lalu jalankan perintah dari folder tugas tersebut:

```bash
cd Tugas-2
flutter pub get
flutter run
```
