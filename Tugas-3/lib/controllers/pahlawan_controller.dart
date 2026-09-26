import 'package:flutter/foundation.dart';
import '../models/hero_model.dart';
import '../models/quiz_model.dart';
import '../repositories/hero_repository.dart';
import '../repositories/quiz_repository.dart';

enum HeroSortMode {
  nameAsc,
  nameDesc,
  birthYearAsc,
  birthYearDesc,
}

class PahlawanController extends ChangeNotifier {
  final HeroRepository _heroRepository;
  final QuizRepository _quizRepository;

  /// Pesan error jika koneksi awal ke Supabase gagal (misal URL/key belum diisi)
  final String? startupError;

  PahlawanController({
    HeroRepository? heroRepository,
    QuizRepository? quizRepository,
    this.startupError,
  })  : _heroRepository = heroRepository ?? HeroRepository(),
        _quizRepository = quizRepository ?? QuizRepository();

  // Data sekarang diambil dari API Supabase (bukan lagi dari HeroData.heroes)
  List<HeroModel> _heroes = [];
  List<QuizQuestion> _quizQuestions = [];
  final Set<String> _favoriteIds = {};

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
      final results = await Future.wait([
        _heroRepository.getAllHeroes(),
        _quizRepository.getAllQuestions(),
      ]);
      _heroes = results[0] as List<HeroModel>;
      _quizQuestions = results[1] as List<QuizQuestion>;
    } catch (e, st) {
      debugPrint('Gagal mengambil data dari API: $e\n$st');
      _errorMessage = 'Gagal mengambil data dari server.\n'
          'Periksa koneksi internet kamu.\n\n($e)';
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
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    final index = dayOfYear % _heroes.length;
    return _heroes[index];
  }

  /// Daftar pahlawan setelah difilter dan diurutkan
  List<HeroModel> get filteredHeroes {
    return _heroes.where((hero) {
      // Filter teks pencarian
      final query = _searchQuery.trim().toLowerCase();
      final matchQuery = query.isEmpty ||
          hero.name.toLowerCase().contains(query) ||
          hero.knownAs.toLowerCase().contains(query) ||
          hero.originCity.toLowerCase().contains(query) ||
          hero.originProvince.toLowerCase().contains(query) ||
          hero.shortBio.toLowerCase().contains(query);

      // Filter wilayah
      final matchRegion = _selectedRegion == 'Semua' || hero.regionGroup == _selectedRegion;

      // Filter era
      final matchEra = _selectedEra == 'Semua' || hero.struggleEra == _selectedEra;

      return matchQuery && matchRegion && matchEra;
    }).toList()
      ..sort((a, b) {
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
      debugPrint('Gagal menyimpan favorit: $e');
      if (wasFavorite) {
        _favoriteIds.add(heroId);
      } else {
        _favoriteIds.remove(heroId);
      }
      notifyListeners();
    }
  }

  bool isFavorite(String heroId) => _favoriteIds.contains(heroId);

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
}
