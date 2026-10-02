# SensorLog - Tugas Sensor

Aplikasi lokal untuk dokumentasi lapangan sesuai spesifikasi tugas:
- Mengambil koordinat GPS dari browser.
- Mengambil/mengunggah foto dari kamera atau galeri.
- Menyimpan foto ke folder `uploads/` dan metadata lokasi ke SQLite (`data/sensorlog.sqlite3`).
- Menampilkan riwayat dan tautan Google Maps.
- Mengekspor data ke CSV.

## Menjalankan

1. Pastikan Python 3.10+ tersedia.
2. Buka PowerShell pada folder ini.
3. Jalankan `python app.py`.
4. Buka `http://127.0.0.1:8000` di browser.

Saat memakai ponsel, jalankan server pada komputer yang sama dengan jaringan lokal dan gunakan alamat IP komputer. Fitur GPS/kamera mengikuti izin browser.
## Supabase (opsional)

Aplikasi otomatis mengirim metadata ke Supabase REST jika dua environment variable ini diisi:

```powershell
$env:SUPABASE_URL = "https://PROJECT_ID.supabase.co"
$env:SUPABASE_ANON_KEY = "YOUR_ANON_KEY"
python app.py
```

Buat tabel `records` di Supabase dengan SQL berikut. Foto tetap disimpan di folder `uploads/` lokal; untuk deployment, folder ini dapat dipindahkan ke Supabase Storage.

```sql
create table public.records (
  id text primary key, created_at timestamptz not null, title text not null,
  category text not null, note text not null, latitude double precision not null,
  longitude double precision not null, accuracy double precision,
  image_filename text not null, compass double precision, tilt double precision,
  battery double precision, ai_suggestion text, sync_status text default 'supabase'
);
```

Jika Supabase sedang tidak tersedia, aplikasi tetap menyimpan data ke SQLite dan menandainya `local`.

## Sensor tambahan dan bantuan AI

- **Kompas:** arah perangkat dalam derajat.
- **Kemiringan:** sudut perangkat dari sensor orientasi.
- **Baterai:** persentase baterai browser bila didukung.
- **Bantuan AI lokal:** mengenali kata kunci lingkungan/infrastruktur, menyarankan kategori, dan merapikan catatan. Fitur ini tidak mengirim teks ke layanan eksternal.
# Menggunakan SensorLog dari HP

`127.0.0.1` hanya berlaku di komputer tempat server berjalan. Agar GPS, kompas, dan kemiringan dapat dipakai dari HP:

1. Sambungkan komputer dan HP ke Wi-Fi yang sama.
2. Di komputer, jalankan:
   ```powershell
   cd "C:\Users\Fito   Dwi Ardiansah\Downloads\Tugas Sensor"
   python app.py
   ```
3. Lihat alamat yang dicetak, misalnya `http://192.168.1.10:8000`.
4. Ketik alamat tersebut di Chrome HP. Jangan ketik `127.0.0.1`.
5. Izinkan lokasi dan sensor gerak saat diminta, lalu tekan **Aktifkan sensor**.

Jika tidak tersambung:
- Pastikan kedua perangkat memakai Wi-Fi yang sama, bukan jaringan tamu.
- Izinkan Python melewati Windows Firewall pada jaringan **Private**.
- Coba alamat IPv4 komputer dari `ipconfig` jika alamat otomatis tidak tepat.

Catatan: sebagian browser hanya mengizinkan sensor orientasi pada HTTPS atau `localhost`. Jika Chrome HP tetap menolak sensor melalui alamat Wi-Fi, GPS masih dapat dipakai; untuk kompas/kemiringan gunakan HTTPS lokal atau jalankan aplikasi melalui hosting HTTPS.
