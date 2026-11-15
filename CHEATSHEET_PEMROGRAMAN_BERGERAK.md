# PANDUAN DAN CHEATSHEET LENGKAP PEMROGRAMAN BERGERAK (FLUTTER)
**Mata Kuliah:** Pemrograman Bergerak (EC234532)  
**Departemen:** Teknik Komputer, FTEIC - Institut Teknologi Sepuluh Nopember (ITS)  
**Dosen Pengampu:** Bambang Widjanarko, S.T., M.T.  
**Penyusun:** Nicholas Benaya / Tim Asisten Cerdas  

---

# BAGIAN 1: CHEATSHEET TIPE I (KOMPREHENSIF & STRAIGHTFORWARD)
*Sebagai Sumber Belajar Mendalam, Referensi Ujian Terbuka, & Pemahaman Konseptual Terstruktur.*

---

## BAB 1: EKOSISTEM FLUTTER & DASAR ARSITEKTUR MULTI-PLATFORM
### 1.1 Perbandingan Pendekatan Pengembangan Mobile
* **Native (Kotlin/Swift):**
  * Akses hardware 100% langsung tanpa jembatan (*bridge*).
  * Performa optimal, namun membutuhkan 2 tim terpisah, 2 codebase berbeda, biaya dan waktu pengembangan 2x lipat.
* **Hybrid / Web-based (Ionic, Cordova):**
  * Menggunakan WebView yang membungkus HTML/CSS/JS.
  * Performa rendah (*UI lag / jank*), tidak cocok untuk animasi kompleks atau komputasi intensif.
* **Cross-Platform Kompilasi Native (Flutter):**
  * Menggunakan bahasa Dart yang dikompilasi langsung ke kode mesin (*Ahead-of-Time / AOT* ke ARM 64-bit).
  * **Self-Rendering Engine:** Flutter tidak menggunakan widget bawaan OEM (native widget Android/iOS). Flutter menggambar setiap piksel sendiri di atas canvas menggunakan engine grafis **Impeller** (atau Skia).
  * Hasil: Tampilan UI 100% identik di Android dan iOS, performa 60–120 FPS konsisten, satu basis kode (*single codebase*).

### 1.2 Struktur Widget Dasar & Filosofi Deklaratif
* **Semuanya adalah Widget:** Antarmuka Flutter disusun secara hierarkis dalam bentuk *Widget Tree*.
* **UI = f(State):** Antarmuka visual adalah proyeksi langsung dari state saat ini. Saat state berubah, fungsi build dieksekusi ulang.
* **StatelessWidget vs StatefulWidget:**
  * `StatelessWidget`: Widget yang tidak memiliki state internal yang bermutasi sepanjang masa hidupnya (contoh: `Text`, `Icon`, `Container` statis).
  * `StatefulWidget`: Widget yang memiliki state dinamis yang dapat berubah sepanjang waktu melalui pemanggilan `setState()` (contoh: `Checkbox`, `TextField`, halaman dinamis).

---

## BAB 2: SIKLUS HIDUP WIDGET (STATE LIFECYCLE) & APPLIFECYCLESTATE
### 2.1 Urutan Siklus Hidup `State<T>` (Wajib Dihafal)
1. **`createState()`**: Dipanggil oleh Flutter saat `StatefulWidget` dimasukkan ke dalam widget tree untuk menginstansiasi objek `State`.
2. **`initState()`**: Dipanggil tepat **satu kali** saat objek State dimasukkan ke context tree.
   * *Kegunaan:* Inisialisasi controller (`TextEditingController`, `AnimationController`, `ScrollController`), langganan stream/listener, pemanggilan awal API / Future.
   * *Pantangan:* Tidak boleh memanggil `BuildContext` yang bergantung pada InheritedWidget (seperti `Theme.of(context)` atau `MediaQuery.of(context)`).
3. **`didChangeDependencies()`**: Dipanggil segera setelah `initState()` dan setiap kali objek `InheritedWidget` yang didengarkannya berubah nilai. Tempat aman untuk mengakses `MediaQuery` atau `Provider`.
4. **`build(BuildContext context)`**: Dipanggil setelah `didChangeDependencies()` dan setiap kali ada pemicu mutasi state (`setState()`, parent rebuild, dependensi berubah). Merender pohon widget.
5. **`didUpdateWidget(covariant T oldWidget)`**: Dipanggil saat widget parent melakukan rebuild dan mengonfigurasi ulang instance widget ini dengan parameter konstruktor baru sementara `runtimeType` dan `key` tetap sama.
6. **`deactivate()`**: Dipanggil saat objek `State` dilepas sementara dari widget tree (misal berpindah cabang).
7. **`dispose()`**: Dipanggil saat objek `State` dihapus permanen dari tree.
   * *Kewajiban:* Wajib menutup/membersihkan resource (`controller.dispose()`, `streamSubscription.cancel()`, timer) untuk mencegah kebocoran memori (*memory leak*).

### 2.2 Hubungan dengan `AppLifecycleState` & Solusi Form Hilang
* **`AppLifecycleState` (dari `WidgetsBindingObserver`):**
  * `resumed`: Aplikasi berada di latar depan dan menerima input pengguna secara aktif.
  * `inactive`: Aplikasi kehilangan fokus (misal: ada panggilan telepon masuk, dialog izin OS, atau pull control center).
  * `paused`: Aplikasi berada di latar belakang (*background*), tidak terlihat oleh pengguna.
  * `detached`: Engine Flutter masih hidup namun terlepas dari tampilan visual host.
* **Mengapa Isian Form Hilang Saat Rotasi / Background?**
  1. *Rotasi Layar:* Dimensi window berubah drastis. Host OS me-restart konfigurasi activity, menyebabkan Flutter menghancurkan widget lama (`deactivate()` -> `dispose()`), lalu membuat instance baru (`createState()` -> `initState()` -> `build()`). Data lokal yang ada di memori widget musnah.
  2. *Background Termination:* Saat aplikasi dalam status `paused`, jika sistem mengalami tekanan memori (*low memory condition*), OS dapat membunuh proses aplikasi secara sepihak.
* **Solusi Form Hilang:**
  * **Solusi 1 (External State / ViewModel):** Letakkan data input di luar siklus hidup widget lokal (di dalam State Management seperti BLoC / Provider / Cubit / Riverpod).
  * **Solusi 2 (Restoration API & Keys):** Gunakan `RestorationScope` bersama `RestorableTextEditingController` atau pasang `PageStorageKey` pada widget form agar Flutter secara otomatis menyimpan dan memulihkan (*restore*) state input dari storage sistem.

---

## BAB 3: STATE MANAGEMENT DI FLUTTER
### 3.1 Ephemeral State vs. App State
| Parameter | Ephemeral (Local) State | App (Shared / Global) State |
| :--- | :--- | :--- |
| **Definisi** | State yang masa pakainya singkat dan hanya dibutuhkan oleh satu widget tunggal. | State yang perlu dibagikan, diakses, atau dimutasi oleh banyak widget di layar berbeda. |
| **Contoh Kasus** | - Animasi tombol suka/bookmark.<br>- Indeks tab aktif pada `BottomNavigationBar`.<br>- Status ekspansi accordion panel. | - Data keranjang belanja (`CartItems` & Total Harga).<br>- Token autentikasi user (`auth_token`).<br>- Pengaturan preferensi tema aplikasi (Dark/Light). |
| **Mekanisme** | `setState()` di dalam `StatefulWidget`, atau `ValueNotifier`. | `Provider`, `Riverpod`, `BLoC` / `Cubit`, `GetX`. |

### 3.2 Arsitektur BLoC (Business Logic Component) / Provider
* **Prinsip Aliran Data Satu Arah (Unidirectional Data Flow):**
  $$\text{UI Layer} \xrightarrow{\text{Event}} \text{BLoC Layer} \xrightarrow{\text{Business Logic}} \text{State Baru (Emit)} \xrightarrow{\text{Stream}} \text{UI Rebuild}$$
* **Mengapa Jauh Lebih Baik daripada `setState()`:**
  1. **Separation of Concerns:** Kode UI murni menangani tampilan; kalkulasi harga, validasi, dan API call berada di class terpisah.
  2. **Performa Rendering:** `setState()` me-rebuild seluruh subtree widget di bawahnya. BLoC/Provider hanya me-rebuild widget `Consumer` / `BlocBuilder` yang secara spesifik mendengarkan state tersebut (*localized build*).
  3. **Kemudahan Pengujian (Testability):** Logika bisnis dapat diuji 100% menggunakan Unit Test tanpa perlu inisialisasi simulator atau rendering UI.
  4. **Maintainability:** Menghindari *spaghetti code* dan *prop drilling* (mengirim data berjenjang melewati puluhan parameter konstruktor).

---

## BAB 4: NETWORKING, HTTP, & PENANGANAN DATA ASYNCHRONOUS
### 4.1 Bedah Masalah Kode Buruk (Anti-Pattern) & Dampaknya
1. **Memanggil `http.get()` di dalam `build()`:**
   * *Dampak fatal:* Rebuild loop tak berujung (*infinite network loop*). Setiap kali UI me-render ulang (keyboard muncul, scroll list, dsb.), HTTP GET dipicu kembali, memboroskan baterai, kuota, dan membuat server hang.
2. **Tidak menangani `ConnectionState` & Error (`snapshot.data!.body`):**
   * *Dampak fatal:* Saat data masih loading (`ConnectionState.waiting`) atau request gagal (`hasError`), `snapshot.data` bernilai `null`. Operator `!` memicu **Red Screen Crash / Crash Fatal (`Null check operator used on null value`)**.
3. **Eksekusi `jsonDecode` Sinkron di dalam Builder:**
   * *Dampak:* Parsing JSON besar di main UI thread memblokir thread rendering, menyebabkan *UI stutter/jank* (drop FPS).
4. **Tipe Data Dinamis & Manual Map Parsing (`as List`, `u['name']`):**
   * *Dampak:* Tidak ada type-safety. Jika key backend berubah atau bernilai null, aplikasi crash akibat `NoSuchMethodError` atau `TypeError`.
5. **`ListView(children: ...)` Tanpa Virtualisasi:**
   * *Dampak:* Seluruh elemen dibuat sekaligus ke memori. Jika ada 1000 data, aplikasi mengalami Out-of-Memory (OOM). Seharusnya menggunakan `ListView.builder`.

### 4.2 Struktur Perbaikan Arsitektur 3-Lapisan (Model - Service - UI)
#### Lapisan 1: Model (`user_model.dart`)
```dart
class User {
  final int id;
  final String name;

  User({required this.id, required this.name});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Tanpa Nama',
    );
  }
}
```

#### Lapisan 2: Service / Repository (`user_service.dart`)
```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'user_model.dart';

class UserService {
  static const String baseUrl = 'https://api.example.com/users';

  Future<List<User>> fetchUsers() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => User.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Gagal memuat data (HTTP ${response.statusCode})');
    }
  }
}
```

#### Lapisan 3: UI Widget (`user_page.dart`)
```dart
import 'package:flutter/material.dart';
import 'user_model.dart';
import 'user_service.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});
  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  late Future<List<User>> _usersFuture;
  final UserService _service = UserService();

  @override
  void initState() {
    super.initState();
    // KUNCI: Future diinisialisasi SATU KALI di initState, BUKAN di build()
    _usersFuture = _service.fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Pengguna')),
      body: FutureBuilder<List<User>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          // 1. Status Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 2. Status Error
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi error: ${snapshot.error}'));
          }
          // 3. Status Kosong
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Data tidak ditemukan.'));
          }
          // 4. Status Sukses (Virtualisasi dengan ListView.builder)
          final users = snapshot.data!;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: CircleAvatar(child: Text('${users[index].id}')),
                title: Text(users[index].name),
              );
            },
          );
        },
      ),
    );
  }
}
```

---

## BAB 5: PENYIMPANAN DATA LOKAL & STRATEGI OFFLINE-FIRST
### 5.1 Perbandingan Opsi Penyimpanan Lokal Flutter
| Aspek | `shared_preferences` | Database Lokal (`sqflite` / `Drift` / `Isar`) | File Mentah (`dart:io` File) |
| :--- | :--- | :--- | :--- |
| **Format & Struktur** | Key-Value primitif (`int`, `String`, `bool`, `double`). | Relasional / Objek terstruktur dengan tabel, kolom, & relasi. | Bebas (plain text, JSON string, gambar binary). |
| **Kemampuan Query** | Tidak ada. Hanya get/set by key langsung. | **Sangat Tinggi:** Filter (`WHERE`), Sort (`ORDER BY`), Indexing, Full-Text Search. | Tidak ada. Wajib baca seluruh file ke memori lalu parse manual. |
| **Kapasitas / Skala** | Sangat kecil (< 1 MB). Cocok untuk preferensi/flag. | Skala menengah hingga besar (> ratusan ribu entitas). | Fleksibel untuk binary besar (caching PDF/media), buruk untuk relasi. |
| **Rekomendasi Kasus Catatan** | Tidak cocok. | **Sangat Cocok:** Memungkinkan pencarian teks, pagination, dan update sebagian. | Kurang efisien untuk catatan dinamis. |

### 5.2 Strategi Sinkronisasi Offline-First
* **Kapan Sinkronisasi Dijalankan:**
  1. *Immediate Event-Driven:* Saat aksi tambah/edit/hapus dilakukan, jika koneksi aktif, langsung kirim ke server.
  2. *Connectivity-Change:* Menggunakan listener `connectivity_plus`. Saat koneksi beralih dari offline ke online, trigger sinkronisasi otomatis di latar belakang.
  3. *App Open & Pull-to-Refresh:* Sinkronisasi rekonsiliasi berkala saat aplikasi dibuka atau pengguna menarik layar ke bawah.
* **Skema Metadata Database Lokal (Wajib Ada):**
  * `id`: UUID client unik (dibuat di client menggunakan `uuid.v4()`).
  * `is_synced`: Integer/Boolean (`0` = lokal belum terkirim, `1` = tersinkron dengan server).
  * `is_deleted`: Flag *soft delete* (`0` = aktif, `1` = dihapus). Catatan yang dihapus offline tidak langsung di-drop dari SQLite lokal agar server tahu catatan tersebut harus dihapus.
  * `updated_at`: Waktu modifikasi dalam format ISO8601 UTC.
* **Penanganan Konflik (Conflict Resolution):**
  * **Last Write Wins (LWW):** Server membandingkan timestamp `updated_at` (UTC). Data dengan timestamp paling akhir dijadikan versi aktif utama.
    * *Kelebihan:* Deterministik, otomatis, tanpa interupsi popup membingungkan bagi pengguna.
    * *Kekurangan:* Risiko *silent overwrite* (kehilangan data jika dua device mengubah paragraf berbeda) atau masalah *clock drift* antar perangkat.
  * *Alternatif yang Lebih Aman:* **Field-Level / Three-Way Merge** atau menyimpan **Version History** di database server.

---

## BAB 6: PEMANFAATAN HARDWARE: SENSOR GPS & KAMERA
### 6.1 Package & Izin Sistem (Permissions)
* **GPS / Lokasi:** Package `geolocator`.
  * *Android:* `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`.
  * *iOS:* `NSLocationWhenInUseUsageDescription`.
* **Kamera & Galeri:** Package `camera` atau `image_picker`.
  * *Android:* `CAMERA`, `READ_EXTERNAL_STORAGE` / `READ_MEDIA_IMAGES`.
  * *iOS:* `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`.

### 6.2 Alur Eksekusi Kode Sensor Ringkas
```dart
// 1. Membaca Posisi GPS
Position position = await Geolocator.getCurrentPosition(
  desiredAccuracy: LocationAccuracy.high,
);
double lat = position.latitude;
double lng = position.longitude;

// 2. Mengambil Gambar dari Kamera
final ImagePicker picker = ImagePicker();
final XFile? photo = await picker.pickImage(source: ImageSource.camera);
if (photo != null) {
  File imageFile = File(photo.path);
}

// 3. Mengunggah ke Server via Multipart HTTP
var request = http.MultipartRequest('POST', Uri.parse('https://api.example.com/upload'));
request.fields['latitude'] = lat.toString();
request.fields['longitude'] = lng.toString();
request.files.add(await http.MultipartFile.fromPath('image', photo!.path));
var response = await request.send();
```

---

## BAB 7: ARSITEKTUR ENTERPRISE, KEAMANAN, & KUALITAS SISTEM
### 7.1 Clean Architecture / Layering
1. **Presentation Layer:** Widgets, Screens, State Holders (BLoC / Cubit / Provider).
2. **Domain Layer:** Entities bisnis (`Order`, `User`), UseCases / Interactors (`PlaceOrderUseCase`). Murni Dart tanpa import Flutter UI.
3. **Data Layer:** Models (`UserModel.fromJson`), Repositories Implementation, Data Sources (Remote via Dio/Http, Local via SQLite/SecureStorage).

### 7.2 Tiga Pilar Keamanan Aplikasi Mobile Wajib
1. **Secure Storage (Hardware Keystore/Keychain):**
   * Token autentikasi (JWT / Refresh Token) dilarang keras disimpan di `SharedPreferences` biasa karena tersimpan sebagai plain-text XML yang mudah dibaca pada perangkat yang di-root/jailbreak.
   * Gunakan `flutter_secure_storage` yang memanfaatkan **Android Keystore** (enkripsi AES hardware) dan **iOS Keychain**.
2. **Komunikasi Terenkripsi & SSL Pinning:**
   * Semua endpoint wajib berjalan di atas HTTPS TLS 1.3.
   * Terapkan **SSL Certificate / Public Key Pinning** menggunakan `dio` atau `SecurityContext` untuk mencegah penyadapan data oleh pihak ketiga (*Man-In-The-Middle / MITM Attack*).
3. **Pemisahan Logika Pembayaran & Idempotency Key:**
   * Mobile app dilarang memproses transaksi pembayaran secara mandiri. Mobile app hanya menampilkan URL / Snap Token pembayaran dari backend.
   * Verifikasi keberhasilan pembayaran wajib melalui **Server-to-Server Webhook** dengan validasi tanda tangan kriptografi (*HMAC / Signature*).
   * Sertakan **Idempotency Key (UUID)** pada header transaksi untuk mencegah penagihan ganda (*double charge*) saat koneksi internet terputus-putus.

### 7.3 Performa & Kualitas (Images, Realtime, Testing)
* **Pemuatan Gambar:** Gunakan `cached_network_image`, format WebP, kompresi thumbnail di server, dan shimmer placeholder.
* **Pembaruan Status Real-time:**
  * Gunakan **Firebase Cloud Messaging (FCM)** untuk push notification saat aplikasi ditutup/background.
  * Gunakan **WebSocket** (misal via Socket.io / Pusher) saat aplikasi aktif di layar pelacakan kurir agar tidak boros baterai dibandingkan polling HTTP terus-menerus.
* **Piramida Pengujian (Testing Pyramid):**
  * *Unit Tests:* Menguji UseCase, kalkulasi diskon/keranjang, dan parsing JSON model.
  * *Widget Tests:* Menguji interaksi komponen UI (tap tombol, validasi form input).
  * *Integration Tests:* Menguji skenario end-to-end (login -> pilih menu -> checkout -> bayar).

---
---

# BAGIAN 2: CHEATSHEET TIPE II (ULTRA-CONDENSED UNTUK KERTAS F4)
> **Format:** Ultra-Ringkas, Padat Formula Kunci, Diagram Alir, Tabel Komparasi, dan Template Kode Inti. Siap disalin/ditulis tangan pada 1 lembar kertas F4 (bolak-balik atau 2-kolom).

---

## 1. WIDGET & STATE LIFECYCLE (KISI-KISI SOAL 1)

### Diagram Alir Urutan Lifecycle `State<T>`
$$\text{createState()} \rightarrow \text{initState()} \rightarrow \text{didChangeDependencies()} \rightarrow \text{build()}$$

* **Rebuild Parent:** $\text{didUpdateWidget()} \rightarrow \text{build()}$
* **Mutasi State:** $\text{setState()} \rightarrow \text{build()}$
* **Pelepasan Sementara:** $\text{deactivate()}$
* **Pelepasan Permanen:** $\text{dispose()}$ $\rightarrow$ **Wajib** `controller.dispose()`, `stream.cancel()`, matikan timer (cegah *memory leak*).

### `AppLifecycleState` (`WidgetsBindingObserver`)
* `resumed`: App di depan (*foreground*), interaktif aktif.
* `inactive`: Kehilangan fokus (panggilan masuk, notifikasi dialog OS).
* `paused`: App di latar belakang (*background*, tertutup app lain).
* `detached`: Engine hidup tanpa antarmuka visual.

### Analisis Kasus Form Hilang & Solusi
* **Penyebab:**
  1. *Rotasi Layar:* Konfigurasi window berubah $\rightarrow$ widget lama di-`dispose()` dan di-rebuild dari awal.
  2. *Background Kill:* Saat `paused`, OS dapat mematikan proses jika *low memory*. State lokal memori hilang.
* **2 Solusi Kunci:**
  1. **External State:** Simpan nilai ke State Management / ViewModel eksternal di luar widget tree.
  2. **Restoration API & Keys:** Gunakan `RestorationScope` + `RestorableTextEditingController` atau pasang `PageStorageKey('form_key')`.

---

## 2. STATE MANAGEMENT (KISI-KISI SOAL 2)

### Komparasi Ephemeral State vs. App State
| Parameter | Ephemeral (Local) State | App (Shared / Global) State |
| :--- | :--- | :--- |
| **Definisi** | Masa hidup singkat, terbatas pada 1 widget tunggal. | Dibagikan lintas halaman/widget di seluruh aplikasi. |
| **Contoh Kasus** | Animasi tombol like, index bottom-nav, toggle koin diskon. | Keranjang belanja (`CartItems`), Auth Token, Tema (Dark/Light). |
| **Mekanisme** | `setState()`, `ValueNotifier`. | `Provider`, `Riverpod`, `BLoC` / `Cubit`, `GetX`. |

### Alur Kerja BLoC (*Unidirectional Data Flow*)
$$\text{UI (View)} \xrightarrow{\text{Event}} \text{BLoC / Logic} \xrightarrow{\text{Emit State}} \text{UI Rebuild via BlocBuilder}$$

### 4 Keunggulan Dibanding `setState()`
1. **Separation of Concerns:** Pemisahan total logika bisnis dari UI.
2. **Localized Rebuild:** Hanya me-render ulang widget daun (*leaf widget*), hemat CPU/baterai.
3. **Testability:** Logika bisnis 100% dapat diuji via Unit Test tanpa UI rendering.
4. **No Prop Drilling:** Akses data global tanpa mengirim parameter berjenjang.

---

## 3. BUG FIXING & ARSITEKTUR HTTP 3-LAYER (KISI-KISI SOAL 3)

### 5 Bug Kritis Kode Asli & Dampaknya
1. `http.get()` di dalam `build()` $\rightarrow$ **Infinite request loop** setiap kali UI me-rebuild.
2. `snapshot.data!.body` $\rightarrow$ **Fatal Red Screen Crash** saat `waiting` atau `hasError` (null-check crash).
3. `jsonDecode` sinkron di `builder` $\rightarrow$ **UI Freeze / Jank** akibat beban main-thread.
4. `as List` & map dinamis $\rightarrow$ **TypeError runtime crash** jika skema API berubah/null.
5. `ListView(children: ...)` $\rightarrow$ **Out of Memory (OOM)** karena tidak ada virtual scroll.

### Template Perbaikan 3-Layer Lengkap

```dart
// [A] MODEL: user_model.dart
class User {
  final int id; final String name;
  User({required this.id, required this.name});
  factory User.fromJson(Map<String, dynamic> j) =>
      User(id: j['id'] ?? 0, name: j['name'] ?? '');
}

// [B] SERVICE: user_service.dart
class UserService {
  Future<List<User>> fetch() async {
    final res = await http.get(Uri.parse('https://api.example.com/users'));
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List).map((e) => User.fromJson(e)).toList();
    }
    throw Exception('Gagal load: ${res.statusCode}');
  }
}

// [C] UI STATE: user_page.dart
class _UserPageState extends State<UserPage> {
  late Future<List<User>> _f;
  @override
  void initState() {
    super.initState();
    _f = UserService().fetch(); // KUNCI: Dipanggil 1x di initState, BUKAN di build()
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<User>>(
        future: _f,
        builder: (c, s) {
          if (s.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (s.hasError) return Center(child: Text('Err: ${s.error}'));
          if (!s.hasData || s.data!.isEmpty) return const Center(child: Text('Kosong'));
          return ListView.builder(
            itemCount: s.data!.length,
            itemBuilder: (c, i) => ListTile(title: Text(s.data![i].name)),
          );
        },
      ),
    );
  }
}
```

---

## 4. PENYIMPANAN DATA & OFFLINE-FIRST (KISI-KISI SOAL 4)

### Komparasi Opsi Penyimpanan Lokal
| Aspek | `shared_preferences` | Database Lokal (`sqflite` / `Drift`) | File Mentah (`dart:io`) |
| :--- | :--- | :--- | :--- |
| **Struktur** | Key-Value primitif. | Relasional / Tabel terstruktur. | Berkas bebas / Binary blob. |
| **Query** | Tidak ada (get/set by key). | **Sangat Kuat:** `WHERE`, `ORDER BY`, FTS. | Tidak ada (baca seluruh file). |
| **Kapasitas** | < 1 MB (flag / token). | Ratusan ribu baris data. | Fleksibel untuk caching media. |
| **Rekomendasi** | Pengaturan tema / auth flag. | **Aplikasi Catatan Harian.** | Simpan file dokumen / foto. |

### Strategi Sinkronisasi & Penanganan Konflik
* **Kapan Sync:** (1) Event-driven saat aksi; (2) Connectivity trigger via `connectivity_plus`; (3) App open / Pull-to-refresh.
* **Kolom SQLite Wajib:** `id` (UUID), `is_synced` (0=pending, 1=synced), `is_deleted` (soft delete), `updated_at` (UTC).
* **Mode Offline:** Simpan ke lokal `is_synced=0` $\rightarrow$ UI respons instan (zero latency) $\rightarrow$ masuk antrean Sync Queue.
* **Konflik:** **Last Write Wins (LWW)** berdasarkan `updated_at` (UTC).
  * *Kelebihan:* Otomatis, deterministik, tanpa popup gangguan ke user.
  * *Kekurangan:* Potensi *silent data loss* jika beda paragraf diedit bersamaan; rentan terhadap *clock drift*.

---

## 5. STUDI KASUS UMKM & ARSITEKTUR ENTERPRISE (KISI-KISI SOAL 5)

* **Pendekatan:** Cross-Platform (Flutter). *Single codebase* Android & iOS, performa AOT native, UI Impeller konsisten.
  * *Trade-off:* Ukuran APK/IPA awal ~15–20 MB, butuh bridging jika SDK payment gateway belum support Flutter native.
* **Clean Architecture:**
  * **Presentation:** Widgets, Screens, BLoC / Cubit.
  * **Domain:** Business Entities (`Order`, `Menu`), UseCases (`PlaceOrder`). Murni Dart.
  * **Data:** Models (`fromJson`), Repository Impl, Remote (Dio) & Local DB (`sqflite`).
* **Navigasi (`GoRouter`):**
  * `/splash` $\rightarrow$ `/login` $\rightarrow$ `/register`
  * `StatefulShellRoute` (BottomNav): `/home`, `/cart`, `/orders`, `/profile`. Sub-route: `/menu/:id`, `/checkout`, `/tracking`.
  * *Redirect Guard:* Lempar ke `/login` jika user belum autentikasi saat mengakses `/checkout`.
* **3 Pilar Keamanan Wajib:**
  1. **Token Storage:** `flutter_secure_storage` (Hardware Keystore Android & Keychain iOS). Hindari `SharedPreferences`.
  2. **Komunikasi:** Wajib HTTPS TLS 1.3 + SSL Certificate Pinning (Cegah MITM attack).
  3. **Pembayaran:** Mobile app hanya terima Snap URL; Verifikasi mutlak via Webhook Server-to-Server + Signature kriptografi.
* **Performa, Kualitas & Testing:**
  * *Gambar Menu:* `cached_network_image` + format WebP + server resizing + shimmer effect.
  * *Real-Time:* FCM Push Notification (background/terminated) + WebSocket (live screen tracking kurir).
  * *Testing:* Unit Test (Logika BLoC & Cart), Widget Test (Form & Card), Integration Test (End-to-End checkout).
* **2 Risiko & Mitigasi:**
  1. *Putus koneksi saat bayar:* Idempotency Key (UUID) di header API + status transaksi *Pending Verification*.
  2. *Scope creep tim kecil:* Terapkan MVP (*Minimum Viable Product*): prioritaskan core flow (Menu $\rightarrow$ Cart $\rightarrow$ Bayar $\rightarrow$ Tracking).

---

## 6. SENSOR HARDWARE (MATERI PRAKTIKUM CLASSROOM)

* **GPS / Lokasi (`geolocator`):**
  * *Izin:* AndroidManifest (`ACCESS_FINE_LOCATION`), Info.plist (`NSLocationWhenInUseUsageDescription`).
  * *Kode:* `Position p = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);`
* **Kamera (`image_picker`):**
  * *Izin:* `CAMERA`, `READ_MEDIA_IMAGES`, `NSCameraUsageDescription`.
  * *Kode:* `final XFile? pic = await ImagePicker().pickImage(source: ImageSource.camera);`
* **Upload Multipart HTTP:**
```dart
var req = http.MultipartRequest('POST', Uri.parse(url));
req.fields['lat'] = p.latitude.toString();
req.fields['lng'] = p.longitude.toString();
req.files.add(await http.MultipartFile.fromPath('file', pic!.path));
var res = await req.send();
```

