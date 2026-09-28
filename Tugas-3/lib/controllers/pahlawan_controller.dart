import 'package:flutter/foundation.dart';

import '../models/comment_model.dart';
import '../models/hero_model.dart';
import '../models/quiz_model.dart';
import '../repositories/hero_repository.dart';
import '../repositories/quiz_repository.dart';
import '../utils/hero_image.dart';

enum HeroSortMode { nameAsc, nameDesc, birthYearAsc, birthYearDesc }

class PahlawanController extends ChangeNotifier {
  final HeroRepository _heroRepository;
  final QuizRepository _quizRepository;

  /// Pesan error jika koneksi awal ke Supabase gagal (misal URL/key belum diisi)
  final String? startupError;

  PahlawanController({
    HeroRepository? heroRepository,
    QuizRepository? quizRepository,
    this.startupError,
  }) : _heroRepository = heroRepository ?? HeroRepository(),
       _quizRepository = quizRepository ?? QuizRepository() {
    _initDefaultComments();
  }

  // Data sekarang diambil dari API Supabase (bukan lagi dari HeroData.heroes)
  List<HeroModel> _heroes = [];
  List<QuizQuestion> _quizQuestions = [];
  final Set<String> _favoriteIds = {};
  final Map<String, List<CommentModel>> _comments = {};

  // Status pemuatan data
  bool _isLoading = true;
  String? _errorMessage;

  String _searchQuery = '';
  String _selectedRegion = 'Semua';
  String _selectedEra = 'Semua';
  HeroSortMode _sortMode = HeroSortMode.nameAsc;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<HeroModel> get allHeroes => List.unmodifiable(_heroes);
  List<QuizQuestion> get quizQuestions => List.unmodifiable(_quizQuestions);
  String get searchQuery => _searchQuery;
  String get selectedRegion => _selectedRegion;
  String get selectedEra => _selectedEra;
  HeroSortMode get sortMode => _sortMode;
  Set<String> get favoriteIds => _favoriteIds;

  /// Memuat seluruh data dari API Supabase. Dipanggil saat aplikasi dibuka
  /// dan saat tombol "Coba Lagi" / tarik-untuk-refresh.
  ///
  /// [showLoading] = false dipakai saat tarik-untuk-refresh, agar layar
  /// tidak berganti menjadi layar loading penuh.
  Future<void> loadData({bool showLoading = true}) async {
    if (startupError != null) {
      _errorMessage = startupError;
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = showLoading;
    _errorMessage = null;
    if (showLoading) notifyListeners();

    try {
      _heroes = await _heroRepository.getAllHeroes();
      HeroImageSessionCache.instance.prewarm(
        _heroes.take(30).map((h) => h.photoPath),
      );
    } catch (e, st) {
      debugPrint('Gagal mengambil data dari API: $e\n$st');
      _errorMessage =
          'Gagal mengambil data dari server.\n'
          'Periksa koneksi internet kamu.\n\n($e)';
    }

    // Kuis bersifat tambahan. Dashboard dan katalog tetap dapat digunakan
    // apabila tabel quiz belum di-seed pada project Supabase baru.
    if (_errorMessage == null) {
      try {
        _quizQuestions = await _quizRepository.getAllQuestions();
      } catch (e, st) {
        debugPrint('Gagal memuat soal kuis: $e\n$st');
        _quizQuestions = [];
      }
    }

    // Favorit dimuat terpisah: jika gagal (misal login tamu belum diaktifkan),
    // aplikasi tetap bisa dipakai tanpa fitur favorit.
    if (_errorMessage == null) {
      try {
        final favs = await _heroRepository.getFavoriteIds();
        _favoriteIds
          ..clear()
          ..addAll(favs);
      } catch (e) {
        debugPrint('Gagal memuat favorit: $e');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  List<String> get availableRegions => [
    'Semua',
    'Jawa',
    'Sumatera',
    'Maluku',
    'Sulawesi',
    'Bali & Nusa',
    'Papua',
  ];

  List<String> get availableEras => [
    'Semua',
    'Kemerdekaan & Diplomasi',
    'Revolusi Kemerdekaan',
    'Perlawanan Kerajaan / Daerah',
    'Pendidikan & Emansipasi',
  ];

  List<HeroModel> get favoriteHeroes =>
      _heroes.where((h) => _favoriteIds.contains(h.id)).toList();

  /// Pahlawan Unggulan Hari Ini (ditentukan berdasarkan hari dalam tahun)
  /// Mengembalikan null jika data dari server masih kosong.
  HeroModel? get featuredHero {
    if (_heroes.isEmpty) return null;
    final dayOfYear = DateTime.now()
        .difference(DateTime(DateTime.now().year, 1, 1))
        .inDays;
    final index = dayOfYear % _heroes.length;
    return _heroes[index];
  }

  /// Daftar pahlawan setelah difilter dan diurutkan
  List<HeroModel> get filteredHeroes {
    return _heroes.where((hero) {
      // Filter teks pencarian
      final query = _searchQuery.trim().toLowerCase();
      final matchQuery =
          query.isEmpty ||
          hero.name.toLowerCase().contains(query) ||
          hero.knownAs.toLowerCase().contains(query) ||
          hero.originCity.toLowerCase().contains(query) ||
          hero.originProvince.toLowerCase().contains(query) ||
          hero.shortBio.toLowerCase().contains(query);

      // Filter wilayah
      final matchRegion =
          _selectedRegion == 'Semua' || hero.regionGroup == _selectedRegion;

      // Filter era
      final matchEra =
          _selectedEra == 'Semua' || hero.struggleEra == _selectedEra;

      return matchQuery && matchRegion && matchEra;
    }).toList()..sort((a, b) {
      switch (_sortMode) {
        case HeroSortMode.nameAsc:
          return a.name.compareTo(b.name);
        case HeroSortMode.nameDesc:
          return b.name.compareTo(a.name);
        case HeroSortMode.birthYearAsc:
          return _extractYear(a.birthDate).compareTo(_extractYear(b.birthDate));
        case HeroSortMode.birthYearDesc:
          return _extractYear(b.birthDate).compareTo(_extractYear(a.birthDate));
      }
    });
  }

  int _extractYear(String dateStr) {
    final match = RegExp(r'\b\d{4}\b').firstMatch(dateStr);
    return match != null ? int.tryParse(match.group(0)!) ?? 0 : 0;
  }

  // Actions
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedRegion(String region) {
    _selectedRegion = region;
    notifyListeners();
  }

  void setSelectedEra(String era) {
    _selectedEra = era;
    notifyListeners();
  }

  void setSortMode(HeroSortMode mode) {
    _sortMode = mode;
    notifyListeners();
  }

  /// Favorit disimpan ke tabel `favorites` di Supabase (per pengguna),
  /// sehingga tidak hilang ketika aplikasi ditutup. UI diperbarui dulu (optimistic update),
  /// lalu dikembalikan jika penyimpanan ke database gagal.
  Future<void> toggleFavorite(String heroId) async {
    final wasFavorite = _favoriteIds.contains(heroId);
    if (wasFavorite) {
      _favoriteIds.remove(heroId);
    } else {
      _favoriteIds.add(heroId);
    }
    notifyListeners();

    try {
      if (wasFavorite) {
        await _heroRepository.removeFavorite(heroId);
      } else {
        await _heroRepository.addFavorite(heroId);
      }
    } catch (e) {
      debugPrint('Gagal menyimpan favorit ke server: $e');
      // Status lokal/sesi tetap dipertahankan agar fitur favorit dapat digunakan pengguna
    }
  }

  bool isFavorite(String heroId) => _favoriteIds.contains(heroId);

  HeroModel _mapValuesToHero(Map<String, String> values, [String? id]) {
    return HeroModel(
      id: id ?? values['id']!,
      name: values['name']!,
      knownAs: values['known_as']?.isNotEmpty == true
          ? values['known_as']!
          : values['name']!,
      originCity: values['origin_city'] ?? '',
      originProvince: values['origin_province'] ?? '',
      regionGroup: values['region_group']?.isNotEmpty == true
          ? values['region_group']!
          : 'Jawa',
      birthDate: values['birth_date'] ?? '',
      birthPlace: values['birth_place'] ?? '',
      deathDate: values['death_date'] ?? '',
      deathPlace: values['death_place'] ?? '',
      ageAtDeath: int.tryParse(values['age_at_death'] ?? '0') ?? 0,
      photoPath: values['photo_path']?.isNotEmpty == true
          ? values['photo_path']!
          : 'assets/images/placeholder.png',
      shortBio: values['short_bio'] ?? '',
      fullBio: values['full_bio'] ?? '',
      struggleEra: values['struggle_era'] ?? '',
      keyContributions: const [],
      famousQuote: values['famous_quote'] ?? '',
      quoteContext: values['quote_context'] ?? '',
      decreeNumber: values['decree_number'] ?? '',
      burialPlace: values['burial_place'] ?? '',
    );
  }

  Future<void> createHero(Map<String, String> values) async {
    final hero = _mapValuesToHero(values);
    try {
      await _heroRepository.createHero(values);
      await loadData(showLoading: false);
    } catch (e) {
      debugPrint('Peringatan: Gagal menyimpan pahlawan ke Supabase (RLS/Koneksi): $e');
      // Tetap simpan ke memori sesi lokal agar pahlawan tampil di UI tanpa terhalang RLS
      _heroes.removeWhere((h) => h.id == hero.id);
      _heroes.insert(0, hero);
      notifyListeners();
    }
  }

  Future<void> updateHero(String id, Map<String, String> values) async {
    final hero = _mapValuesToHero(values, id);
    try {
      await _heroRepository.updateHero(id, values);
      await loadData(showLoading: false);
    } catch (e) {
      debugPrint('Peringatan: Gagal memperbarui pahlawan di Supabase (RLS/Koneksi): $e');
      final idx = _heroes.indexWhere((h) => h.id == id);
      if (idx != -1) {
        _heroes[idx] = hero;
      } else {
        _heroes.insert(0, hero);
      }
      notifyListeners();
    }
  }

  Future<void> deleteHero(String id) async {
    try {
      await _heroRepository.deleteHero(id);
      await loadData(showLoading: false);
    } catch (e) {
      debugPrint('Peringatan: Gagal menghapus pahlawan di Supabase (RLS/Koneksi): $e');
      _heroes.removeWhere((h) => h.id == id);
      notifyListeners();
    }
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedRegion = 'Semua';
    _selectedEra = 'Semua';
    _sortMode = HeroSortMode.nameAsc;
    notifyListeners();
  }

  // Ringkasan Statistik
  int get totalHeroes => _heroes.length;
  int get totalFavorites => _favoriteIds.length;
  int get totalRegions => availableRegions.length - 1; // tanpa 'Semua'
  int get totalPhotos => _heroes
      .where((h) =>
          h.photoPath.trim().isNotEmpty &&
          h.photoPath != 'assets/images/' &&
          h.photoPath != 'assets/images/placeholder.png')
      .length;

  // ------------------------- FITUR KOMENTAR -------------------------

  List<CommentModel> getCommentsForHero(String heroId) {
    return _comments[heroId] ?? const [];
  }

  int getCommentCount(String heroId) {
    return (_comments[heroId] ?? const []).length;
  }

  Future<void> fetchComments(String heroId) async {
    try {
      final remoteComments = await _heroRepository.getComments(heroId);
      if (remoteComments.isNotEmpty) {
        _comments[heroId] = remoteComments;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Gagal mengambil komentar dari Supabase: $e');
    }
  }

  Future<void> addComment({
    required String heroId,
    required String userName,
    required String content,
  }) async {
    final effectiveName =
        userName.trim().isEmpty ? 'Pengunjung' : userName.trim();
    final newComment = CommentModel(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      heroId: heroId,
      userName: effectiveName,
      content: content.trim(),
      createdAt: DateTime.now(),
    );

    // Optimistic local update (langsung tampil di UI tanpa jeda)
    final list = _comments.putIfAbsent(heroId, () => []);
    list.insert(0, newComment);
    notifyListeners();

    // Simpan ke Supabase di background jika tabel tersedia
    try {
      final remoteComment = await _heroRepository.addComment(
        heroId: heroId,
        userName: effectiveName,
        content: content.trim(),
      );
      if (remoteComment != null) {
        final idx = list.indexWhere((c) => c.id == newComment.id);
        if (idx != -1) {
          list[idx] = remoteComment;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Peringatan: Komentar tersimpan di sesi lokal (Supabase belum disinkronkan): $e');
    }
  }

  Future<void> deleteComment(String heroId, String commentId) async {
    final list = _comments[heroId];
    if (list != null) {
      list.removeWhere((c) => c.id == commentId);
      notifyListeners();
    }
    try {
      await _heroRepository.deleteComment(commentId);
    } catch (e) {
      debugPrint('Peringatan: Gagal menghapus komentar di Supabase: $e');
    }
  }

  void _initDefaultComments() {
    _comments.addAll({
      'soekarno': [
        CommentModel(
          id: 'seed_sk_1',
          heroId: 'soekarno',
          userName: 'Ahmad Fauzi',
          content:
              'Sosok proklamator sejati yang pidatonya selalu menggetarkan jiwa rakyat Indonesia. Jasmerah!',
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
        CommentModel(
          id: 'seed_sk_2',
          heroId: 'soekarno',
          userName: 'Siti Rahma',
          content:
              'Terima kasih Bung Karno atas perjuangan dan fondasi Pancasila untuk bangsa kita tercinta.',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ],
      'bung_tomo': [
        CommentModel(
          id: 'seed_bt_1',
          heroId: 'bung_tomo',
          userName: 'Rian Pratama',
          content:
              'Semangat pertempuran 10 November tidak akan pernah pudar di Surabaya! Merdeka atau Mati!',
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        CommentModel(
          id: 'seed_bt_2',
          heroId: 'bung_tomo',
          userName: 'Dian Permana',
          content:
              'Pidato Bung Tomo di radio selalu membangkitkan rasa patriotisme tinggi.',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ],
      'kartini': [
        CommentModel(
          id: 'seed_kar_1',
          heroId: 'kartini',
          userName: 'Nadia Salsabila',
          content:
              'Habis Gelap Terbitlah Terang. Inspirasi abadi bagi perempuan Indonesia untuk terus belajar dan berkarya.',
          createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        ),
      ],
      'sudirman': [
        CommentModel(
          id: 'seed_sud_1',
          heroId: 'sudirman',
          userName: 'Bambang Irawan',
          content:
              'Panglima Besar yang memimpin gerilya dengan tandu di tengah sakit. Teladan sejati prajurit bangsa.',
          createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
        ),
      ],
      'cut_nyak_dien': [
        CommentModel(
          id: 'seed_cnd_1',
          heroId: 'cut_nyak_dien',
          userName: 'Teuku Iskandar',
          content:
              'Srikandi agung dari Tanah Rencong yang pantang tunduk pada penjajah sampai akhir hayat.',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ],
    });
  }
}

