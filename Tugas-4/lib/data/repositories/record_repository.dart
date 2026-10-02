import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../models/record_draft.dart';
import '../models/record_model.dart';

/// Satu-satunya tempat yang bicara langsung dengan Supabase (database + storage).
class RecordRepository {
  RecordRepository(this._client);

  final SupabaseClient _client;
  static const _uuid = Uuid();

  static const _mimeByExt = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
  };

  String _publicUrl(String path) =>
      _client.storage.from(AppConstants.photoBucket).getPublicUrl(path);

  Future<List<RecordModel>> fetchAll() async {
    try {
      final rows = await _client
          .from(AppConstants.recordsTable)
          .select()
          .order('created_at', ascending: false);
      return rows
          .map<RecordModel>((m) => RecordModel.fromMap(m, photoUrl: _publicUrl(m['photo_path'] as String)))
          .toList();
    } catch (e) {
      throw _wrap(e, 'Gagal memuat data.');
    }
  }

  Future<RecordModel> create(RecordDraft draft, File photo) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AppException('Sesi belum siap. Mulai ulang aplikasi.');

    var ext = photo.path.split('.').last.toLowerCase();
    if (!_mimeByExt.containsKey(ext)) ext = 'jpg';
    final path = '$userId/${_uuid.v4()}.$ext';

    try {
      await _client.storage.from(AppConstants.photoBucket).upload(
            path,
            photo,
            fileOptions: FileOptions(contentType: _mimeByExt[ext]),
          );
    } catch (e) {
      throw _wrap(e, 'Gagal mengunggah foto.');
    }

    try {
      final row = await _client
          .from(AppConstants.recordsTable)
          .insert(draft.toInsertMap(path))
          .select()
          .single();
      return RecordModel.fromMap(row, photoUrl: _publicUrl(path));
    } catch (e) {
      // Hindari file foto yatim jika insert gagal.
      await _client.storage.from(AppConstants.photoBucket).remove([path]).catchError((_) => <FileObject>[]);
      throw _wrap(e, 'Gagal menyimpan catatan.');
    }
  }

  Future<void> delete(RecordModel record) async {
    try {
      await _client.from(AppConstants.recordsTable).delete().eq('id', record.id);
      await _client.storage.from(AppConstants.photoBucket).remove([record.photoPath]);
    } catch (e) {
      throw _wrap(e, 'Gagal menghapus catatan.');
    }
  }

  AppException _wrap(Object error, String fallback) {
    if (error is SocketException) {
      return const AppException('Tidak ada koneksi internet.');
    }
    return AppException(fallback);
  }
}
