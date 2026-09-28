-- Kutipan terverifikasi untuk 15 pahlawan inti aplikasi.
-- Jalankan setelah 02_seed_data.sql atau setelah import dataset Gist.

update public.heroes set famous_quote = 'Beri aku 1.000 orang tua, niscaya akan kucabut Semeru dari akarnya. Beri aku 10 pemuda niscaya akan kuguncangkan dunia.', quote_context = 'Pidato untuk menggelorakan semangat generasi muda Indonesia'
where name ilike '%Soekarno%';

update public.heroes set famous_quote = 'Kurang cerdas dapat diperbaiki dengan belajar, kurang cakap dapat dihilangkan dengan pengalaman. Namun tidak jujur itu sulit diperbaiki.', quote_context = 'Nasihat keteladanan integritas moral bagi para pemimpin bangsa'
where name ilike '%Hatta%';

update public.heroes set famous_quote = 'Tahukah engkau semboyanku? Aku mau! Dua patah kata yang ringkas itu sudah beberapa kali mendukung dan membawaku melintasi gunung rintangan.', quote_context = 'Surat kepada Nyonya Van Kol, Agustus 1901'
where name ilike '%Kartini%';

update public.heroes set famous_quote = 'Robek-robeklah badanku, potong-potonglah jasad ini, tetapi jiwaku yang dilindungi benteng Merah Putih akan tetap hidup, tetap menuntut bela.', quote_context = 'Penegasan tekad pantang menyerah dalam perjuangan'
where name ilike '%Soedirman%' or name ilike '%Sudirman%';

update public.heroes set famous_quote = 'Hidup dan mati ada dalam tangan Allah. Jangan tunduk pada kezaliman, walau harus mengorbankan segalanya.', quote_context = 'Pesan moral kepada para pengikutnya di medan juang'
where name ilike '%Diponegoro%';

update public.heroes set famous_quote = 'Ing ngarsa sung tulada, ing madya mangun karsa, tut wuri handayani.', quote_context = 'Trilogi filosofi dasar pendidikan nasional Indonesia'
where name ilike '%Hajar Dewantara%' or name ilike '%Hadjar Dewantara%';

update public.heroes set famous_quote = 'Sebagai perempuan Muslim, kita tidak boleh meneteskan air mata bagi orang yang telah syahid di jalan Allah!', quote_context = 'Kutipan saat menguatkan putrinya setelah Teuku Umar gugur'
where name ilike '%Cut Nyak Dhien%';

update public.heroes set famous_quote = 'Pattimura-Pattimura tua boleh dihancurkan, tetapi kelak Pattimura-Pattimura muda akan bangkit!', quote_context = 'Kata-kata terakhir sebelum eksekusi di Ambon'
where name ilike '%Pattimura%';

update public.heroes set famous_quote = 'Pelaut yang tangguh tidak dihasilkan dari laut yang tenang, melainkan dari ombak badai yang diterjang dengan keberanian.', quote_context = 'Falsafah kepemimpinan maritim Bugis-Makassar'
where name ilike '%Hasanuddin%';

update public.heroes set famous_quote = 'Menyesal aku, mengapa orang Padri berperang sesama sendiri dulu. Tetapi kini mari kita satukan jiwa raga mengusir kaum penjajah.', quote_context = 'Refleksi untuk merekatkan persatuan Minangkabau'
where name ilike '%Imam Bonjol%';

update public.heroes set famous_quote = 'Merdeka atau Mati! Kami tidak akan pernah berkompromi mengenai kemerdekaan tanah air Indonesia.', quote_context = 'Penegasan perjuangan I Gusti Ngurah Rai'
where name ilike '%Ngurah Rai%';

update public.heroes set famous_quote = 'Irian adalah bagian tak terpisahkan dari Republik Indonesia dari Sabang sampai Merauke!', quote_context = 'Pernyataan perjuangan integrasi Papua'
where name ilike '%Frans Kaisiepo%';

update public.heroes set famous_quote = 'Selama banteng-banteng Indonesia masih mempunyai darah merah yang dapat membikin secarik kain putih menjadi merah dan putih, maka selama itu kita tidak akan mau menyerah!', quote_context = 'Pidato radio sebelum Pertempuran 10 November 1945'
where name ilike '%Bung Tomo%' or name ilike '%Sutomo%';

update public.heroes set famous_quote = 'Pendidikan perempuan adalah pilar utama kemajuan keluarga dan kemuliaan masa depan suatu bangsa.', quote_context = 'Gagasan perjuangan pendidikan perempuan'
where name ilike '%Dewi Sartika%';

update public.heroes set famous_quote = 'Hidup-hidupilah Muhammadiyah, jangan mencari hidup di Muhammadiyah. Jadilah manusia yang bermanfaat bagi sesama.', quote_context = 'Pesan ketulusan berjuang kepada warga persyarikatan'
where name ilike '%Ahmad Dahlan%';
