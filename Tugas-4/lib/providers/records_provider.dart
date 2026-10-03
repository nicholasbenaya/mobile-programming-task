import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../data/models/record_category.dart';
import '../data/models/record_model.dart';
import '../data/repositories/record_repository.dart';

/// State daftar catatan: muat, cari, filter, tambah, hapus.
class RecordsProvider extends ChangeNotifier {
  RecordsProvider(this._repository);

  final RecordRepository _repository;
  String? _userId;

  List<RecordModel> _records = [];
  bool _loading = false;
  String? _error;
  RecordCategory? _filter;
  String _query = '';

  /// Dipanggil saat akun berganti: kosongkan data lama, muat data akun baru.
  void onUserChanged(String? userId) {
    if (userId == _userId) return;
    _userId = userId;
    _records = [];
    _error = null;
    _filter = null;
    _query = '';
    _loading = false;
    // Ditunda agar tidak memanggil notifyListeners saat widget tree sedang build.
    Future.microtask(userId != null ? load : notifyListeners);
  }

  List<RecordModel> get records => _records;
  bool get loading => _loading;
  String? get error => _error;
  RecordCategory? get filter => _filter;

  List<RecordModel> get visible {
    final q = _query.trim().toLowerCase();
    return _records.where((r) {
      final matchCategory = _filter == null || r.category == _filter;
      final matchQuery = q.isEmpty || r.title.toLowerCase().contains(q) || r.note.toLowerCase().contains(q);
      return matchCategory && matchQuery;
    }).toList();
  }

  int get todayCount {
    final now = DateTime.now();
    return _records.where((r) {
      final d = r.createdAt.toLocal();
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).length;
  }

  int get weekCount {
    final limit = DateTime.now().subtract(const Duration(days: 7));
    return _records.where((r) => r.createdAt.isAfter(limit)).length;
  }

  Future<void> load() async {
    final uid = _userId;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _repository.fetchAll();
      if (uid == _userId) _records = data; // abaikan hasil akun lama
    } on AppException catch (e) {
      if (uid == _userId) _error = e.message;
    } finally {
      if (uid == _userId) _loading = false;
      notifyListeners();
    }
  }

  void addLocal(RecordModel record) {
    _records = [record, ..._records];
    notifyListeners();
  }

  Future<void> delete(RecordModel record) async {
    await _repository.delete(record);
    _records = _records.where((r) => r.id != record.id).toList();
    notifyListeners();
  }

  void setFilter(RecordCategory? category) {
    _filter = category;
    notifyListeners();
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }
}
