// ignore_for_file: avoid_print

import 'dart:io';

void main() {
  final quotes = <String, Map<String, String>>{
    'a_h_nasution_0': {
      'quote': 'Tentara bukan merupakan suatu kasta tersendiri di dalam masyarakat. Tentara adalah bagian dari rakyat yang memikul senjata demi kedaulatan nusa dan bangsa.',
      'context': 'Doktrin Perang Gerilya dan Tentara Nasional Indonesia',
    },
    'abdul_muis_2': {
      'quote': 'Kemajuan suatu bangsa tidak akan tercapai tanpa pendidikan budi pekerti dan akal budi bangsanya sendiri.',
      'context': 'Pemikiran kemajuan bangsa dalam sastra dan pergerakan nasional',
    },
    'abdu_halim_3': {
      'quote': 'Agama dan persatuan bangsa harus berjalan beriringan untuk membebaskan rakyat dari kebodohan dan penindasan.',
      'context': 'Prinsip perjuangan Persyarikatan Ulama Majalengka',
    },
    'abdulrahman_saleh_4': {
      'quote': 'Pengabdian ilmu pengetahuan dan sayap kedirgantaraan kita persembahkan seutuhnya bagi kemerdekaan tanah air.',
      'context': 'Dedikasi perintisan kedokteran dan AURI',
    },
    'achmad_rifai_5': {
      'quote': 'Menentang kezaliman dan penjajahan adalah kewajiban agama demi tegaknya martabat kemanusiaan.',
      'context': 'Ajaran dakwah perlawanan kultural terhadap kolonialisme',
    },
    'achmad_subardjo_6': {
      'quote': 'Kemerdekaan ini kita rebut dengan pengorbanan jiwa dan raga, bukan hadiah atau belas kasihan dari bangsa lain.',
      'context': 'Rapat perumusan naskah Proklamasi Kemerdekaan di Rengasdengklok',
    },
    'adenan_kapau_gani_8': {
      'quote': 'Diplomasi ekonomi dan penyelundupan senjata kita tempuh demi menembus blokade penjajah dan menghidupi republik.',
      'context': 'Perjuangan menembus blokade laut Belanda di Sumatera Selatan',
    },
    'adisucipto_9': {
      'quote': 'Kembangkan sayapmu mengarungi angkasa raya demi membela kedaulatan tanah pusaka Indonesia.',
      'context': 'Amanat perintisan Sekolah Penerbang AURI Yogyakarta',
    },
    'ageng_tirtayasa_10': {
      'quote': 'Lebih baik tanah Banten bermandikan darah daripada tunduk pada monopoli dan kelicikan kaum kumpeni.',
      'context': 'Perlawanan mempertahankan kedaulatan Kesultanan Banten dari VOC',
    },
    'agung_hanyokrokusumo_11': {
      'quote': 'Pantang bagi kesatria Mataram membiarkan penjajah bercokol dan menindas bumi Nusantara.',
      'context': 'Serangan besar Mataram ke Batavia melawan VOC',
    },
    'agus_salim_12': {
      'quote': 'Leiden is lijden. Memimpin adalah menderita dan melayani, bukan menumpuk harta atau kekuasaan.',
      'context': 'Falsafah kepemimpinan dan integritas hidup berbangsa',
    },
    'ahmad_dahlan_13': {
      'quote': 'Hidup-hidupilah Muhammadiyah, jangan mencari hidup di Muhammadiyah. Jadilah manusia yang bermanfaat bagi sesama.',
      'context': 'Pesan ketulusan berjuang kepada warga persyarikatan',
    },
    'ahmad_yani_14': {
      'quote': 'TNI tidak pernah dan tidak boleh menyerah kepada siapapun juga kecuali kepada bangsa dan negara Indonesia.',
      'context': 'Penegasan loyalitas prajurit kepada konstitusi dan NKRI',
    },
    'albertus_soegijapranata_15': {
      'quote': '100% Katolik, 100% patriotik Indonesia. Keduanya manunggal dalam pengabdian kepada tanah air.',
      'context': 'Surat pastoral menegaskan komitmen kebangsaan umat Katolik',
    },
    'ali_haji_16': {
      'quote': 'Barang siapa mengenal yang empat, maka ia itulah orang yang ma\'rifat. Bahasa menunjukkan bangsa.',
      'context': 'Gurindam Dua Belas dan perintisan bahasa persatuan Melayu',
    },
    'alimin_17': {
      'quote': 'Kemerdekaan sejati adalah lenyapnya penindasan manusia atas manusia dan bangsa atas bangsa.',
      'context': 'Pergerakan antikolonial awal abad ke-20',
    },
    'amir_hamzah_18': {
      'quote': 'Sunyi itu duka, sunyi itu kudus, tetapi cinta pada nusa bangsa adalah bakti yang takkan pernah padam.',
      'context': 'Renungan sastra dan pengabdian kebangsaan di Sumatera Timur',
    },
    'andi_djemma_19': {
      'quote': 'Kerajaan Luwu dengan segenap rakyat dan wilayahnya berdiri teguh di belakang Republik Indonesia.',
      'context': 'Pernyataan kesetiaan Luwu bergabung dengan NKRI 1945',
    },
    'arie_frederik_lasut_21': {
      'quote': 'Kekayaan tambang dan geologi bumi pertiwi ini adalah hak milik bangsa Indonesia, pantang diserahkan kembali pada penjajah.',
      'context': 'Keteguhan mempertahankan data pertambangan nasional hingga gugur',
    },
    'bagindo_azizchan_22': {
      'quote': 'Langkahilah dulu mayatku, baru Padang bisa kalian kuasai!',
      'context': 'Penolakan tegas garis demarkasi Belanda di Padang',
    },
    'basuki_rahmat_23': {
      'quote': 'Keselamatan bangsa dan keutuhan negara di atas segala kepentingan pribadi maupun golongan.',
      'context': 'Penyelamatan stabilitas nasional pasca pergolakan 1965',
    },
    'bau_massepe_24': {
      'quote': 'Lebih baik mati ditembak daripada harus mengkhianati tanah air dan menjual kedaulatan bangsa.',
      'context': 'Penolakan tunduk pada Westerling di Parepare',
    },
    'bernard_wilhelm_lapiran_25': {
      'quote': 'Merah Putih berkibar di tanah Minahasa sebagai bukti kami adalah bagian tak terpisahkan dari Republik Indonesia.',
      'context': 'Peristiwa Merah Putih 14 Februari 1946 di Manado',
    },
    'cipto_mangunkusumo_26': {
      'quote': 'Hari depan kita ada di tangan kita sendiri, bukan atas belas kasihan penguasa kolonial.',
      'context': 'Tulisan tajam perjuangan Indische Partij',
    },
    'cut_nyak_dhien_26': {
      'quote': 'Sebagai perempuan Muslim, kita tidak boleh meneteskan air mata bagi orang yang telah syahid di jalan Allah!',
      'context': 'Menguatkan pejuang Aceh setelah Teuku Umar gugur',
    },
    'cut_nyak_meutia_27': {
      'quote': 'Jangan pernah berhenti melangkah sebelum musuh angkat kaki dari tanah rencong kita.',
      'context': 'Memimpin perlawanan gerilya rakyat Aceh',
    },
    'd_i_pandjaitan_28': {
      'quote': 'Tugas adalah kehormatan, kejujuran adalah jalan hidup, dan iman adalah benteng pertahanan jiwa.',
      'context': 'Prinsip kedisiplinan dan integritas militer',
    },
    'dewi_sartika_28': {
      'quote': 'Pendidikan perempuan adalah pilar utama kemajuan keluarga dan kemuliaan masa depan suatu bangsa.',
      'context': 'Gagasan pendirian Sakola Istri Jawa Barat',
    },
    'diponegoro_29': {
      'quote': 'Hidup dan mati ada dalam tangan Allah. Jangan tunduk pada kezaliman, walau harus mengorbankan segalanya.',
      'context': 'Seruan Perang Jawa menegakkan keadilan',
    },
    'djatikusumo_30': {
      'quote': 'Prajurit sejati mengabdi tanpa pamrih, menjunjung tinggi sumpah setia kepada nusa dan bangsa.',
      'context': 'Peletakan fondasi awal KASAD pertama TNI AD',
    },
    'douwes_dekker_31': {
      'quote': 'Hindia (Indonesia) untuk orang Hindia! Bangsa ini berhak mengatur rumah tangganya sendiri.',
      'context': 'Doktrin nasionalisme pergerakan Indische Partij',
    },
    'fakhruddin_32': {
      'quote': 'Pena jurnalisme dan dakwah harus menjadi suluh penerang yang membangkitkan kesadaran rakyat terjajah.',
      'context': 'Perjuangan pers Islam dan pergerakan kebangsaan',
    },
    'fatmawati_33': {
      'quote': 'Jahitan Merah Putih ini kurajut dengan linangan air mata dan doa, agar berkibar abadi bagi kemerdekaan Indonesia.',
      'context': 'Menjahit Bendera Pusaka Sang Saka Merah Putih 1945',
    },
    'fl_tobing_34': {
      'quote': 'Kesehatan rakyat adalah kekuatan utama perjuangan kemerdekaan kita.',
      'context': 'Pelayanan medis pejuang di Tapanuli dan Sumatera Utara',
    },
    'frans_kaisiepo_34': {
      'quote': 'Irian adalah bagian tak terpisahkan dari Republik Indonesia dari Sabang sampai Merauke!',
      'context': 'Penegasan Konferensi Malino 1946',
    },
    'gatot_mangkupraja_35': {
      'quote': 'Pemuda Nusantara harus memiliki tentara sendiri untuk mempertahankan kedaulatan tanah airnya.',
      'context': 'Gagasan pembentukan Tentara Sukarela Pembela Tanah Air (PETA)',
    },
    'gatot_soebroto_36': {
      'quote': 'Jangan pernah ragu dalam bertindak demi kebenaran. Prajurit harus berani dan membela rakyat kecil.',
      'context': 'Ketegasan dan kepedulian kepemimpinan militer',
    },
    'halim_perdanakusuma_37': {
      'quote': 'Angkasa nusantara adalah kedaulatan kita, terbangkan Merah Putih setinggi-tingginya!',
      'context': 'Misi penerbangan dan pasokan senjata AURI',
    },
    'hamengkubuwana_i_38': {
      'quote': 'Sawiji, greget, sengguh, ora mingkuh (Fokus, bersemangat, percaya diri, pantang mundur).',
      'context': 'Falsafah kepemimpinan dan ketahanan Kasultanan Yogyakarta',
    },
    'hamka_39': {
      'quote': 'Kecantikan yang abadi terletak pada keelokan adab dan ketinggian ilmu, bukan pada keelokan wajah dan pakaian.',
      'context': 'Falsafah moral budi pekerti dalam Tafsir Al-Azhar dan Tasawuf Modern',
    },
    'harun_thohir_40': {
      'quote': 'Kami menjalankan tugas negara dengan penuh kehormatan, jiwa dan raga kami persembahkan untuk Merah Putih.',
      'context': 'Keteguhan prajurit Korps Komando Operasi AL',
    },
    'hasan_basry_46': {
      'quote': 'Kalimantan Selatan adalah bagian tak terpisahkan dari Republik Indonesia, kami menolak segala bentuk kompromi dengan penjajah!',
      'context': 'Proklamasi 17 Mei 1949 Divisi IV ALRI Kalimantan',
    },
    'hasanuddin_47': {
      'quote': 'Pelaut yang tangguh tidak dihasilkan dari laut yang tenang, melainkan dari ombak badai yang diterjang dengan keberanian.',
      'context': 'Falsafah kepemimpinan maritim Bugis-Makassar',
    },
    'hazairin_49': {
      'quote': 'Hukum nasional harus berakar kuat pada nilai-nilai budaya dan kesadaran hukum rakyat Indonesia sendiri.',
      'context': 'Perintisan madzhab hukum nasional Indonesia',
    },
    'herman_johannes_50': {
      'quote': 'Ilmu pengetahuan dan teknologi adalah senjata perjuangan untuk membangun kemandirian bangsa.',
      'context': 'Peracik bahan peledak gerilya dan rektor Universitas Gadjah Mada',
    },
    'i_gusti_ketut_puja_52': {
      'quote': 'Sunda Kecil dengan segenap jiwa raganya menyatu dalam keagungan Negara Kesatuan Republik Indonesia.',
      'context': 'Penetapan integrasi Bali dan Nusa Tenggara dalam sidang PPKI 1945',
    },
    'i_gusti_ngurah_made_agung_53': {
      'quote': 'Sing ada kocap surud ring payudan (Pantang bagi kesatria mundur setapak pun dari medan pertempuran).',
      'context': 'Puputan Badung 1906 mempertahankan kehormatan tanah air',
    },
    'i_j_kasimo_h_55': {
      'quote': 'Politik adalah sarana pengabdian kebajikan dan ketahanan pangan rakyat, bukan panggung intrik kekuasaan.',
      'context': 'Rencana Kasimo Plan demi swasembada pangan nasional',
    },
    'ida_anak_agung_gde_agung_56': {
      'quote': 'Diplomasi berdaulat adalah kunci mengukuhkan martabat kemerdekaan Indonesia di mata dunia internasional.',
      'context': 'Perundingan diplomasi pengakuan kedaulatan Indonesia',
    },
    'idham_chalid_57': {
      'quote': 'Ukhuwah dan kebangsaan adalah dua sisi dari satu mata uang yang sama dalam menjaga keutuhan NKRI.',
      'context': 'Pesan persatuan ormas Islam dan kebangsaan',
    },
    'ilyas_ya_kub_58': {
      'quote': 'Kebenaran dan kemerdekaan tidak bisa dipenjara oleh dinding kolonialisme.',
      'context': 'Perlawanan pejuang Minangkabau di masa pembuangan Boven Digoel',
    },
    'imam_bonjol_59': {
      'quote': 'Menyesal aku, mengapa orang Padri berperang sesama sendiri dulu. Tetapi kini mari kita satukan jiwa raga mengusir kaum penjajah.',
      'context': 'Refleksi persatuan Minangkabau mengusir Belanda',
    },
    'iskandar_muda_60': {
      'quote': 'Adat bak Po Teumeureuhom, Hukom bak Syiah Kuala (Adat bersendi pada hukum keadilan, hukum bersendi pada syariat).',
      'context': 'Falsafah kepemimpinan dan kejayaan Kesultanan Aceh Darussalam',
    },
    'ismail_marzuki_61': {
      'quote': 'Gugur bungaku di taman bakti, di haribaan pertiwi. Jiwaku senantiasa berlagu bagi Indonesia pusaka.',
      'context': 'Ciptaan lagu perjuangan menggelorakan heroisme bangsa',
    },
    'iswahyudi_62': {
      'quote': 'Tugas penerbangan ini demi mengantarkan kedaulatan bangsa, pantang surut meski maut menghadang.',
      'context': 'Misi diplomasi udara dan pengadaan senjata AURI',
    },
    'iwa_kusumasumantri_63': {
      'quote': 'Hukum dan keadilan sosial harus berpihak kepada rakyat pekerja yang tertindas.',
      'context': 'Perumusan konstitusi dan pembelaan hak buruh nasional',
    },
    'izaak_huru_doko_64': {
      'quote': 'Pendidikan adalah jembatan emas bagi putra-putri Timor untuk bangkit setara dengan seluruh saudara sebangsa.',
      'context': 'Perintisan pendidikan dan pergerakan pemuda Timor',
    },
    'j_a_dimara_65': {
      'quote': 'Merah Putih adalah lambang kehormatan kami, Irian Barat selamanya adalah pangkuan ibu pertiwi Indonesia!',
      'context': 'Gerilya pembebasan Irian Barat dan inspirasi Monumen Pembebasan Irian Barat',
    },
    'j_leimena_66': {
      'quote': 'Dalam berpolitik, kejujuran dan ketulusan hati nurani adalah modal utama seorang negarawan sejati.',
      'context': 'Teladan integritas dan etika diplomasi perdamaian',
    },
    'jamin_ginting_67': {
      'quote': 'Bumi Karo adalah tanah tumpah darah kita, pantang mundur setapak pun menghadapi agresi penjajah.',
      'context': 'Memimpin Komando Pasukan Gerilya Tanah Karo Sumatera Utara',
    },
    'john_lie_68': {
      'quote': 'Bila Tuhan bersama kita, siapakah yang dapat melawan kita? Jalur laut ini kita terobos demi amunisi kemerdekaan.',
      'context': 'Operasi penyelundupan senjata menembus blokade laut Belanda',
    },
    'juanda_kartawijaya_69': {
      'quote': 'Segala perairan di sekitar, di antara dan yang menghubungkan pulau-pulau adalah bagian mutlak wilayah kedaulatan Indonesia.',
      'context': 'Deklarasi Djuanda 13 Desember 1957 menyatukan wilayah laut Nusantara',
    },
    'k_s_tubun_70': {
      'quote': 'Kewajiban seorang bhayangkara adalah menjaga pos dan keselamatan negara hingga hembusan napas terakhir.',
      'context': 'Keteguhan menjaga pos jaga hingga gugur dalam peristiwa G30S',
    },
    'katamso_d_71': {
      'quote': 'Pancasila adalah falsafah abadi bangsa Indonesia yang tidak boleh diubah oleh siapapun.',
      'context': 'Keteguhan membela Pancasila di Korem 072/Pamungkas Yogyakarta',
    },
    'ki_bagus_hadikusumo_72': {
      'quote': 'Ketuhanan Yang Maha Esa adalah fundamen moral dan spiritual bangsa yang memancarkan keadilan bagi seluruh rakyat.',
      'context': 'Perumusan sila pertama Pancasila dalam sidang BPUPKI/PPKI',
    },
    'ki_hadjar_dewantara_73': {
      'quote': 'Ing ngarsa sung tulada, ing madya mangun karsa, tut wuri handayani.',
      'context': 'Trilogi filosofi dasar pendidikan nasional Taman Siswa',
    },
    'ki_mangunsarkoro_74': {
      'quote': 'Sistem pendidikan nasional wajib berakar pada kebudayaan luhur bangsa sendiri, bukan menjiplak bangsa asing.',
      'context': 'Perumusan Undang-Undang Pendidikan Nasional pertama Republik Indonesia',
    },
    'kiras_bangun_75': {
      'quote': 'Bersatu kita teguh mempertahankan tanah leluhur dari keserakahan penjajah kolonial.',
      'context': 'Perjuangan menyatukan klan-klan Karo melawan ekspansi Belanda',
    },
    'kusumah_atmaja_76': {
      'quote': 'Keadilan hukum harus berdiri tegak tanpa gentar terhadap kekuasaan politik maupun tekanan apapun.',
      'context': 'Peletakan fondasi kehakiman agung Indonesia merdeka',
    },
    'l_n_palar_77': {
      'quote': 'Suara Indonesia merdeka harus menggema lantang di panggung Perserikatan Bangsa-Bangsa.',
      'context': 'Diplomasi gigih di PBB memperjuangkan pengakuan kedaulatan RI',
    },
    'la_maddukelleng_78': {
      'quote': 'Kedaulatan Wajo dan laut Nusantara adalah milik rakyat yang merdeka, pantang tunduk pada hegemoni VOC!',
      'context': 'Perlawanan maritim membebaskan Selat Makassar dari monopoli Belanda',
    },
    'm_h_thamrin_79': {
      'quote': 'Kemerdekaan ekonomi rakyat jelata dan perbaikan nasib kaum kromo di kampung-kampung adalah tujuan utama pergerakan kita.',
      'context': 'Pidato pembelaan rakyat jelata di Volksraad',
    },
    'm_t_haryono_80': {
      'quote': 'Prajurit sejati memegang teguh sumpah prajurit, tidak akan goyah oleh bujuk rayu maupun ancaman.',
      'context': 'Keteguhan prinsip perwira tinggi TNI AD',
    },
    'maria_walanda_maramis_81': {
      'quote': 'Kaum ibu adalah pendidik pertama dan utama bagi tunas-tunas masa depan bangsa. Kemajuan wanita adalah kemajuan bangsa.',
      'context': 'Pendirian PIKAT di Minahasa',
    },
    'martha_christina_tiahahu_82': {
      'quote': 'Saya tidak sudi menerima belas kasihan penjajah! Lebih baik mati di laut bebas daripada tunduk pada Belanda.',
      'context': 'Aksi mogok makan menolak pengobatan Belanda hingga gugur di Laut Banda',
    },
    'marthen_indey_83': {
      'quote': 'Irian Barat adalah darah daging Indonesia, jangan pernah biarkan kolonial memecah belah persatuan kita.',
      'context': 'Memimpin pergerakan bawah tanah integrasi Papua ke NKRI',
    },
    'mas_isman_84': {
      'quote': 'KOSGORO: Pengabdian, kerakyatan, dan solidaritas adalah jalan membela kehormatan rakyat jelata.',
      'context': 'Pembinaan Tentara Republik Indonesia Pelajar (TRIP)',
    },
    'mas_mansur_85': {
      'quote': 'Langkah perjuangan harus berani, tegas, dan berpijak pada kemaslahatan umat serta kemerdekaan bangsa.',
      'context': 'Empat Serangkai pergerakan nasional Indonesia',
    },
    'maskun_sumadireja_86': {
      'quote': 'Penjara Sukamiskin tidak akan pernah mampu membelenggu cita-cita luhur Indonesia Merdeka!',
      'context': 'Pembelaan bersama Bung Karno dalam Indonesia Menggugat',
    },
    'moehammad_jasin_87': {
      'quote': 'Polisi Istimewa menyatakan diri bersatu dengan rakyat dan berdiri teguh sebagai Polisi Republik Indonesia yang merdeka.',
      'context': 'Proklamasi Polisi Surabaya 21 Agustus 1945',
    },
    'mohammad_hatta_88': {
      'quote': 'Kurang cerdas dapat diperbaiki dengan belajar, kurang cakap dapat dihilangkan dengan pengalaman. Namun tidak jujur itu sulit diperbaiki.',
      'context': 'Nasihat keteladanan integritas moral bagi para pemimpin bangsa',
    },
    'natsir_89': {
      'quote': 'Untuk mencapai sesuatu, harus diperjuangkan dulu. Seperti mengambil buah kelapa, tidak cukup hanya menunggu buah itu jatuh.',
      'context': 'Mosi Integral Natsir 1950 yang mengembalikan Indonesia ke NKRI',
    },
    'mohammad_yamin_90': {
      'quote': 'Cita-cita persatuan Indonesia itu bukan omong kosong, tetapi benar-benar didukung oleh kekuatan-kekuatan yang timbul pada akar sejarah bangsa kita.',
      'context': 'Pidato Kongres Pemuda II 1928 melahirkan Sumpah Pemuda',
    },
    'muhammad_mangundiprojo_91': {
      'quote': 'Pertahankan kedaulatan Surabaya dan bendera Merah Putih hingga titik darah penghabisan!',
      'context': 'Pemimpin pertempuran mempertahankan Surabaya 1945',
    },
    'mustopo_92': {
      'quote': 'Berjuanglah dengan kecerdikan dan keberanian luar biasa, jadikan musuh bingung dengan taktik perang rakyat kita.',
      'context': 'Panglima Pasukan Teratai Jawa Timur',
    },
    'muwardi_93': {
      'quote': 'Kesiapsiagaan barisan pemuda adalah benteng pelindung Proklamasi Kemerdekaan bangsa kita.',
      'context': 'Pimpinan Barisan Pelopor dalam pengamanan Proklamasi 17 Agustus 1945',
    },
    'nani_wartabone_94': {
      'quote': 'Hari ini tanggal 23 Januari 1942, kita bangsa Indonesia di Gorontalo sudah merdeka, bebas dari penjajahan!',
      'context': 'Peristiwa Patriotik 23 Januari 1942 memerdekakan Gorontalo',
    },
    'nur_ali_95': {
      'quote': 'Pantang berkhianat pada agama dan tanah air. Pertahankan garis Bekasi sampai darah penghabisan!',
      'context': 'Komandan Laskar Rakyat Bekasi menghadapi agresi Sekutu dan NICA',
    },
    'nyai_ahmad_dahlan_96': {
      'quote': 'Kaum perempuan jangan tertinggal, belajarlah dan beramallah demi kemajuan nusa serta tegaknya syiar kebaikan.',
      'context': 'Pendirian Aisyiyah untuk pemberdayaan perempuan Indonesia',
    },
    'nyi_ageng_serang_97': {
      'quote': 'Untuk mencapai cita-cita yang luhur, kita harus sanggup menderita dan berkorban tanpa pamrih.',
      'context': 'Nasihat perang gerilya dalam Perang Diponegoro',
    },
    'opu_daeng_risadju_98': {
      'quote': 'Kalau hanya karena menuntut kemerdekaan bangsaku aku harus disiksa dan dipenjara, maka aku ikhlas lahir dan batin.',
      'context': 'Keteguhan bangsawan wanita Luwu menolak melepaskan keanggotaan PSII',
    },
    'oto_iskandar_dinata_99': {
      'quote': 'Indonesia Merdeka harus menjadi jembatan emas menuju kemakmuran dan keadilan bagi seluruh rakyat.',
      'context': 'Tokoh pergerakan Pasundan dan pengusul Soekarno-Hatta sebagai Presiden & Wapres pertama',
    },
    'pangeran_sambernyowo_100': {
      'quote': 'Rumangsa melu handarbeni, wajib melu hangrungkebi, mulat sarira hangrasa wani (Merasa ikut memiliki, wajib ikut membela, berani mawas diri).',
      'context': 'Tri Dharma keprajuritan Mangkunegaran',
    },
    'pajongga_daeng_ngalle_101': {
      'quote': 'Kemerdekaan Indonesia adalah harga mati bagi rakyat Polongbangkeng, pantang tunduk pada penjajah kolonial!',
      'context': 'Memimpin Laskar Pemberontak Rakyat Indonesia Sulawesi (LAPRIS)',
    },
    'pakubuwana_vi_102': {
      'quote': 'Raga boleh diasingkan ke Ambon, tetapi kesetiaan jiwa raga tetap menyatu bersama perjuangan Diponegoro.',
      'context': 'Dukungan rahasia Kraton Surakarta kepada Pangeran Diponegoro',
    },
    'pakubuwana_x_103': {
      'quote': 'Kemajuan peradaban dan modernisasi pendidikan adalah perisai pelindung martabat bangsa di panggung zaman.',
      'context': 'Pembangunan fasilitas publik, rumah sakit, dan sekolah modern Surakarta',
    },
    'pangeran_antasari_104': {
      'quote': 'Haram manyarah, waja sampai kaputing! (Pantang menyerah, berjuang teguh bagai baja hingga titik darah penghabisan).',
      'context': 'Semboyan perang Banjar menghadapi kolonialisme Belanda',
    },
    'pattimura_105': {
      'quote': 'Pattimura-Pattimura tua boleh dihancurkan, tetapi kelak Pattimura-Pattimura muda akan bangkit!',
      'context': 'Pesan terakhir sebelum dieksekusi di Benteng Victoria Ambon',
    },
    'pierre_tendean_106': {
      'quote': 'Saya ajudan Jenderal Nasution! Tembaklah saya jika itu yang kalian inginkan, jangan sentuh komandan saya!',
      'context': 'Pengorbanan melindungi pimpinan dalam peristiwa 1 Oktober 1965',
    },
    'pong_tiku_107': {
      'quote': 'Benteng Tana Toraja tidak akan pernah menyerah kepada penindas, kedaulatan tanah leluhur adalah harga diri kami!',
      'context': 'Perlawanan heroik di Benteng Baruppu Tana Toraja',
    },
    'r_e_martadinata_109': {
      'quote': 'Jalesveva Jayamahe! Di laut kita jaya. Bangsa bahari yang besar harus menguasai samudranya sendiri.',
      'context': 'Pembinaan kekuatan armada ALRI mengawal kedaulatan maritim',
    },
    'r_suprapto_110': {
      'quote': 'Ketaatan kepada sumpah prajurit dan kehormatan konstitusi adalah harga mati yang tidak dapat ditawar.',
      'context': 'Keteguhan memegang sumpah perwira tinggi TNI AD',
    },
    'raden_tumenggung_setia_pahlawan_111': {
      'quote': 'Kedaulatan Melawi dan tanah Dayak adalah milik rakyat, pantang menyerahkan sejengkal tanah pun kepada kumpeni.',
      'context': 'Perlawanan Kesultanan Sintang Melawi Kalimantan Barat',
    },
    'radin_inten_ii_112': {
      'quote': 'Selama hayat dikandung badan, pantang bagi rakyat Lampung tunduk pada hukum kolonial penjajah.',
      'context': 'Memimpin benteng pertahanan Gunung Rajabasa Lampung',
    },
    'raja_haji_fisabilillah_113': {
      'quote': 'Biar tersungkur di medan juang, jangan sekali-kali surut menghadapi armada penjajah di perairan Melayu!',
      'context': 'Gugur syahid dalam pertempuran laut Teluk Ketapang melawan VOC',
    },
    'rajiman_wedyodiningrat_114': {
      'quote': 'Atas dasar apakah negara Indonesia merdeka yang akan kita dirikan ini? Pertanyaan inilah yang menyatukan jiwa kita.',
      'context': 'Pembukaan sidang pertama BPUPKI 29 Mei 1945',
    },
    'ranggong_daeng_romo_115': {
      'quote': 'Kemerdekaan ini ditebus dengan darah, pantang bagi kami mundur setapak pun di tanah Sulawesi!',
      'context': 'Perang gerilya LAPRIS melawan agresi militer Belanda',
    },
    'rasuna_said_116': {
      'quote': 'Kaum wanita harus berani bersuara lantang menuntut hak dan kemerdekaan bangsanya di mimbar perjuangan.',
      'context': 'Pidato politik PERMI memperjuangkan kemerdekaan',
    },
    'saharjo_117': {
      'quote': 'Pohon beringin pengayoman: hukum harus mengayomi, membimbing, dan memanusiakan manusia, bukan semata menghukum.',
      'context': 'Peletakan lambang hukum nasional dan sistem pemasyarakatan',
    },
    'samanhudi_119': {
      'quote': 'Bumiputra harus bersatu dalam perniagaan agar tidak terus-menerus ditindas dan diperas oleh modal asing.',
      'context': 'Pendirian Sarekat Dagang Islam (SDI) 1905 di Solo',
    },
    'silas_papare_120': {
      'quote': 'Jangan biarkan sejengkal pun tanah Papua lepas dari pangkuan Ibu Pertiwi Indonesia!',
      'context': 'Pendirian Partai Kemerdekaan Irian Indonesia (PKII)',
    },
    'sisingamangaraja_xii_121': {
      'quote': 'Ahu do manangkon kedaulatan ni tano Batak! Pantang bagi kami menyerahkan tanah leluhur kepada penjajah kolonial.',
      'context': 'Perlawanan mempertahankan Tano Batak hingga titik darah penghabisan',
    },
    's_parman_122': {
      'quote': 'Kewaspadaan intelijen negara adalah mata dan telinga yang melindungi keselamatan seluruh tumpah darah bangsa.',
      'context': 'Pengabdian intelijen militer menjaga kedaulatan negara',
    },
    'slamet_riyadi_123': {
      'quote': 'Serang musuh tanpa ragu! Semangat juang kita lebih kuat dari segala persenjataan modern mereka.',
      'context': 'Perebutan kembali kota Solo dan operasi penumpasan pemberontakan',
    },
    'sudirman_124': {
      'quote': 'Robek-robeklah badanku, potong-potonglah jasad ini, tetapi jiwaku yang dilindungi benteng Merah Putih akan tetap hidup, tetap menuntut bela.',
      'context': 'Penegasan tekad pantang menyerah dalam perang gerilya',
    },
    'sugiono_125': {
      'quote': 'Kesetiaan prajurit kepada pimpinan dan negara adalah benteng tegak yang tidak boleh rapuh.',
      'context': 'Pengorbanan membela Pancasila di Yogyakarta',
    },
    'suharso_126': {
      'quote': 'Keterbatasan fisik bukanlah akhir dari kehidupan. Rehabilitasi adalah jalan memulihkan martabat manusia Indonesia.',
      'context': 'Pendirian Lembaga Rehabilitasi Centra Solo bagi pejuang kemerdekaan',
    },
    'sukarjo_wiryopranoto_127': {
      'quote': 'Surat kabar adalah senjata politik rakyat untuk mengikis tuntas imperialisme dari bumi Indonesia.',
      'context': 'Pelopor pers nasional dan jurnalisme pergerakan',
    },
    'sukarni_128': {
      'quote': 'Kemerdekaan ini harus kita proklamasikan atas nama bangsa Indonesia sendiri, sekarang juga tanpa campur tangan Jepang!',
      'context': 'Desakan pemuda dalam peristiwa Rengasdengklok 1945',
    },
    'sukarno_129': {
      'quote': 'Beri aku 1.000 orang tua, niscaya akan kucabut Semeru dari akarnya. Beri aku 10 pemuda niscaya akan kuguncangkan dunia.',
      'context': 'Pidato menggelorakan tekad generasi muda',
    },
    'sultan_daeng_raja_130': {
      'quote': 'Keluarga bangsawan dan rakyat harus lebur menjadi satu dalam membela kedaulatan Republik Indonesia.',
      'context': 'Tokoh pergerakan Sulawesi Selatan dan delegasi PPKI',
    },
    'sultan_mahmud_badaruddin_ii_131': {
      'quote': 'Bumi Sriwijaya Palembang pantang diperintah bangsa asing. Lebih baik dibumihanguskan daripada jatuh ke tangan kumpeni!',
      'context': 'Perang Palembang menghadapi agresi Inggris dan Belanda',
    },
    'sultan_nuku_132': {
      'quote': 'Maluku dan Papua adalah satu kesatuan laut yang berdaulat, kami usir penjajah dari tanah rempah pusaka ini!',
      'context': 'Perjuangan pembebasan Kepulauan Maluku dan Irian dari VOC',
    },
    'sultan_syahrir_133': {
      'quote': 'Hidup yang tidak dipertaruhkan tidak akan pernah dimenangkan. Diplomasi yang cerdas adalah senjata terkuat bangsa merdeka.',
      'context': 'Perjuangan diplomasi kemerdekaan Indonesia',
    },
    'sultan_thaha_syaifuddin_134': {
      'quote': 'Selama Sungai Batanghari masih mengalir, Kesultanan Jambi tidak akan pernah tunduk pada penjajah Belanda!',
      'context': 'Memimpin perlawanan rakyat Jambi dari hutan belantara hingga wafat 1904',
    },
    'supeno_135': {
      'quote': 'Pembangunan karakter pemuda dan olahraga adalah pondasi ketahanan fisik serta moral bangsa yang merdeka.',
      'context': 'Menteri Pembangunan dan Pemuda gerilya 1948',
    },
    'supomo_136': {
      'quote': 'Negara kesatuan Indonesia adalah negara kekeluargaan yang menyatu dengan segenap lapisan rakyatnya.',
      'context': 'Perumusan pokok-pokok kaidah negara dalam sidang BPUPKI',
    },
    'supriyadi_137': {
      'quote': 'Kita tidak boleh lagi melihat rakyat kita disiksa romusha. Bangkitlah para prajurit PETA, demi kemerdekaan bangsa!',
      'context': 'Memimpin pemberontakan tentara PETA di Blitar 14 Februari 1945',
    },
    'suroso_138': {
      'quote': 'Kesejahteraan kaum buruh dan pamong praja adalah urat nadi pembangunan pemerintahan republik yang bersih.',
      'context': 'Peletak tata kelola kepegawaian dan transmigrasi nasional',
    },
    'suryo_139': {
      'quote': 'Bila saudara-saudara sekalian ditembak, jangan gentar! Balaslah tembakan itu demi membela kehormatan Surabaya!',
      'context': 'Pidato radio bersejarah Gubernur Jawa Timur menyambut ultimatum Sekutu 9 November 1945',
    },
    'suryopranoto_140': {
      'quote': 'Kaum buruh tani adalah tulang punggung negeri, hak-haknya harus diperjuangkan secara serentak dan berani!',
      'context': 'Pemimpin pergerakan serikat buruh pribumi',
    },
    'sutomo_141': {
      'quote': 'Selama banteng-banteng Indonesia masih mempunyai darah merah yang dapat membikin secarik kain putih menjadi merah dan putih, maka selama itu kita tidak akan mau menyerah!',
      'context': 'Pidato radio pembakar semangat pertempuran 10 November 1945',
    },
    'sutomo_142': {
      'quote': 'Budi Utomo adalah langkah awal kebangkitan bangsa. Belajar dan berorganisasilah untuk kemajuan tanah air!',
      'context': 'Pendirian Boedi Oetomo 20 Mei 1908',
    },
    'sutoyo_siswomiharjo_143': {
      'quote': 'Hukum militer dan sumpah perwira adalah kompas moral yang tidak boleh goyah dalam badai politik.',
      'context': 'Penegakan korps hukum militer Indonesia',
    },
    'syafrudding_prawiranegara_144': {
      'quote': 'Pemerintah Darurat Republik Indonesia (PDRI) membuktikan kepada dunia internasional bahwa Indonesia belum dan tidak akan pernah mati!',
      'context': 'Mandat pembentukan PDRI di pedalaman Sumatera Barat saat Agresi Militer Belanda II',
    },
    'syarif_kasim_ii_145': {
      'quote': 'Mahkota dan seluruh harta kekayaan Kesultanan Siak ini kami serahkan seutuhnya untuk perjuangan kemerdekaan Republik Indonesia.',
      'context': 'Penyerahan 13 juta gulden dan kedaulatan Siak mendukung NKRI',
    },
    't_b_simatupang_146': {
      'quote': 'Mempertahankan kemerdekaan tidak cukup hanya dengan senapan, tetapi dengan strategi, ilmu pengetahuan, dan ketulusan iman.',
      'context': 'Peletak dasar strategi perang kemerdekaan dan Kepala Staf Angkatan Perang RI',
    },
    't_m_hasan_147': {
      'quote': 'Kekayaan alam dan semangat pantang mundur rakyat Sumatera kita satukan penuh untuk tegaknya kedaulatan Republik Indonesia.',
      'context': 'Gubernur pertama Sumatera dan tokoh kunci PDRI',
    },
    'tan_malaka_148': {
      'quote': 'Ingatlah! Bahwa dari dalam kubur, suara saya akan lebih keras daripada dari atas bumi! Tuan rumah tidak akan berunding dengan maling yang menjarah rumahnya.',
      'context': 'Karya Madilog dan prinsip perjuangan Merdeka 100%',
    },
    'teuku_nyak_arief_149': {
      'quote': 'Persatuan seluruh uleebalang dan alim ulama adalah kunci kemenangan mempertahankan Aceh sebagai daerah modal kemerdekaan.',
      'context': 'Residen pertama Aceh mempertahankan daerah modal RI',
    },
    'teuku_tjik_ditoro_150': {
      'quote': 'Perang Sabil menegakkan keadilan dan mengusir penjajah adalah kewajiban suci yang mengalirkan kemuliaan syahid.',
      'context': 'Memimpin kebangkitan Perang Aceh melawan Belanda',
    },
    'teuku_umar_151': {
      'quote': 'Beungoh singoh geutanyoe jep kupi di keude Meulaboh, atawa mandum matee syahid! (Besok pagi kita minum kopi di Meulaboh, atau kita semua gugur syahid!).',
      'context': 'Sumpah taktik perang gerilya di Meulaboh sebelum gugur 1899',
    },
    'tien_suharto_152': {
      'quote': 'Kebudayaan Nusantara adalah jiwa bangsa. Dengan merawat warisan luhur tradisi, kita memperkokoh persatuan Indonesia.',
      'context': 'Penggagas TMII dan pelestarian budaya bangsa',
    },
    'tirto_adi_suryo_153': {
      'quote': 'Surat kabar adalah alat penerang bagi bangsa yang sedang tertidur lelap dalam kungkungan kolonialisme.',
      'context': 'Pendirian koran Medan Prijaji 1907 sebagai pelopor pers pribumi',
    },
    'tjilik_riwut_154': {
      'quote': 'Belantara Dayak dan seluruh pelosok pedalaman Kalimantan adalah benteng kedaulatan Republik Indonesia.',
      'context': 'Tokoh penerjunan pertama AURI di Kalimantan dan Gubernur Kalteng',
    },
    'tuanku_tambusai_155': {
      'quote': 'Pantang surut setapak pun di Benteng Dalu-Dalu! Kedaulatan dan kehormatan agama tidak dapat dibeli dengan emas kaum penjajah.',
      'context': 'Pertahanan heroik Benteng Dalu-Dalu Riau dalam Perang Padri',
    },
    'untung_suropati_156': {
      'quote': 'Dari seorang budak belian menjadi pembela kedaulatan tanah Jawa, pantang tunduk pada kelicikan VOC!',
      'context': 'Perlawanan heroik di Batavia hingga Pasuruan',
    },
    'urip_sumoharjo_157': {
      'quote': 'Aneh, suatu tentara tanpa pucuk pimpinan. Tetapi marilah kita tata barisan ini dengan disiplin baja demi kemerdekaan bangsa!',
      'context': 'Perintisan pembentukan Tentara Keamanan Rakyat (TKR) Yogyakarta',
    },
    'usman_janatin_158': {
      'quote': 'Tugas negara kami laksanakan tanpa pamrih. Gugur di medan bakti adalah kemuliaan tertinggi seorang prajurit marinir.',
      'context': 'Keteguhan prajurit Korps Komando Operasi AL',
    },
    'w_r_supratman_159': {
      'quote': 'Indonesia Raya, merdeka, merdeka! Hiduplah Indonesia Raya. Lagu ini kupersembahkan untuk mempersatukan jiwa bangsaku.',
      'context': 'Lagu kebangsaan Indonesia Raya pada Sumpah Pemuda 1928',
    },
    'w_z_johannes_160': {
      'quote': 'Pengabdian ilmu kedokteran dan radiologi harus menjangkau rakyat kecil di pelosok Nusantara.',
      'context': 'Perintis radiologi kedokteran pertama Indonesia',
    },
    'wahidin_sudirohusodo_162': {
      'quote': 'Mencerdaskan kehidupan bangsa lewat dana pendidikan (Studiefonds) adalah kunci mengangkat martabat kaum bumiputra.',
      'context': 'Kampanye keliling Jawa yang menginspirasi berdirinya Boedi Oetomo',
    },
    'wolter_monginsidi_163': {
      'quote': 'Setia hingga akhir dalam keyakinan! Saya mati dengan tenang demi kemerdekaan tanah air dan rakyat Indonesia.',
      'context': 'Kata-kata terakhir sebelum dieksekusi regu tembak Belanda di Makassar 1949',
    },
    'yos_sudarso_164': {
      'quote': 'Kobarkan semangat pertempuran! Terus maju pantang mundur demi pembebasan Irian Barat!',
      'context': 'Seruan terakhir dari anjungan KRI Macan Tutul dalam Pertempuran Laut Aru 1962',
    },
    'zainal_mustafa_166': {
      'quote': 'Tunduk menyembah kepada kaisar Jepang (Seikerei) adalah haram! Kita hanya menyembah Allah dan menuntut keadilan rakyat!',
      'context': 'Perlawanan heroik rakyat dan santri Singaparna Tasikmalaya 1944',
    },
    'zainul_arifin_167': {
      'quote': 'Laskar Hizbullah berjuang menjaga keutuhan Republik dan martabat umat dari segala ancaman penjajahan.',
      'context': 'Panglima Pasukan Hizbullah dan Ketua DPR-GR',
    },
  };

  final buffer = StringBuffer();
  buffer.writeln('-- ==============================================================');
  buffer.writeln('-- 04_complete_hero_quotes.sql');
  buffer.writeln('-- Pembaruan kutipan bersejarah dan konteks untuk seluruh pahlawan');
  buffer.writeln('-- ==============================================================\n');

  for (final entry in quotes.entries) {
    final id = entry.key;
    final quote = entry.value['quote']!.replaceAll("'", "''");
    final context = entry.value['context']!.replaceAll("'", "''");

    buffer.writeln(
      "update public.heroes set famous_quote = '$quote', quote_context = '$context' where id = '$id';",
    );
  }

  final outFile = File('c:/Users/kegz/Desktop/Folder iko/Projects Local/skor_app/Tugas-3/supabase/04_complete_hero_quotes.sql');
  outFile.writeAsStringSync(buffer.toString());
  print('Successfully generated 04_complete_hero_quotes.sql with ${quotes.length} hero quotes.');
}
