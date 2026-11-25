# Login Supabase Auth dan foto bukti Ronda

1. Jalankan `shift_swaps.sql`, `ronda_incidents.sql`, dan `ronda_photo_storage.sql` di Supabase SQL Editor.
2. Simpan `SUPABASE_URL` dan `SUPABASE_SECRET_KEY` (atau legacy `SUPABASE_SERVICE_ROLE_KEY`) secara lokal di `.env.local` (file ini sudah di-ignore Git). Secret/service-role key hanya untuk provisioning, jangan taruh di aplikasi Flutter.
3. Instal dependensi skrip jika belum tersedia: `npm install --no-save @supabase/supabase-js`.
4. Jalankan: `node tools/seed_ronda_auth_users.mjs`.

Skrip membuat/memperbarui lima akun Auth yang cocok dengan demo Ronda. Password awal masing-masing `password123`. Login aplikasi menggunakan nomor WhatsApp tersebut dan password. Ganti password sebelum pemakaian di luar demo.

Foto laporan petugas dan bukti penyelesaian SOS diunggah ke bucket privat `ronda-evidence`. Path dan metadata laporan disimpan di `incident_reports`; dashboard admin meminta signed URL melalui sesi Auth dan policy RT.
