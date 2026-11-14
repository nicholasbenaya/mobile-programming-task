import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../models/record_draft.dart';
import '../models/record_model.dart';

/// Satu-satunya tempat yang bicara langsung dengan Supabase (database + storage).
/// Bucket foto bersifat PRIVAT: foto ditampilkan lewat signed URL sementara,
/// dan hanya pemilik akun yang bisa membuatnya (RLS storage).
class RecordRepository {
  RecordRepository(this._client);

  final SupabaseClient _client;
  static const _uuid = Uuid();
  static const _urlTtlSeconds = 6 * 60 * 60; // 6 jam

  static const _mimeByExt = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
  };

  StorageFileApi get _bucket => _client.storage.from(AppConstants.photoBucket);

  Future<List<RecordModel>> fetchAll() async {
    try {
      final rows = await _client
          .from(AppConstants.recordsTable)
          .select()
          .order('created_at', ascending: false);
      if (rows.isEmpty) return [];

      final paths = [for (final m in rows) m['photo_path'] as String];
      final signed = await _bucket.createSignedUrls(paths, _urlTtlSeconds);

      return [
        for (var i = 0; i < rows.length; i++)
          RecordModel.fromMap(rows[i], photoUrl: i < signed.length ? signed[i].signedUrl : ''),
      ];
    } catch (e) {
      throw _wrap(e, 'Gagal memuat data.');
    }
  }

  Future<RecordModel> create(RecordDraft draft, File photo) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AppException('Sesi berakhir. Silakan masuk lagi.');

    var ext = photo.path.split('.').last.toLowerCase();
    if (!_mimeByExt.containsKey(ext)) ext = 'jpg';
    // Folder pertama = id pemilik, dicek oleh policy storage.
    final path = '$userId/${_uuid.v4()}.$ext';

    try {
      await _bucket.upload(path, photo, fileOptions: FileOptions(contentType: _mimeByExt[ext]));
    } catch (e) {
      throw _wrap(e, 'Gagal mengunggah foto.');
    }

    try {
      final row = await _client
          .from(AppConstants.recordsTable)
          .insert(draft.toInsertMap(path))
          .select()
          .single();
      final url = await _bucket.createSignedUrl(path, _urlTtlSeconds);
      return RecordModel.fromMap(row, photoUrl: url);
    } catch (e) {
      // Hindari file foto yatim jika insert gagal.
      await _bucket.remove([path]).catchError((_) => <FileObject>[]);
      throw _wrap(e, 'Gagal menyimpan catatan.');
    }
  }

  Future<void> delete(RecordModel record) async {
    try {
      await _client.from(AppConstants.recordsTable).delete().eq('id', record.id);
      await _bucket.remove([record.photoPath]);
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
