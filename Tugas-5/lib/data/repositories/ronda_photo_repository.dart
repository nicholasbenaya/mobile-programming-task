import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';

/// Upload foto bukti Ronda ke bucket privat.
/// Storage RLS memvalidasi RT dan role dari app_metadata JWT, bukan dari UI.
class RondaPhotoRepository {
  RondaPhotoRepository(this._client);

  final SupabaseClient _client;
  static const _uuid = Uuid();
  static const _urlTtlSeconds = 60 * 30;

  StorageFileApi get _bucket =>
      _client.storage.from(AppConstants.rondaPhotoBucket);

  Future<String> upload({
    required File photo,
    required String rtId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException(
          'Masuk dengan akun Supabase untuk mengunggah foto.');
    }

    final ext = photo.path.split('.').last.toLowerCase();
    const mimeByExt = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'webp': 'image/webp',
    };
    final mime = mimeByExt[ext];
    if (mime == null) {
      throw ArgumentError('Format foto harus JPG, PNG, atau WebP.');
    }
    if (await photo.length() > 8 * 1024 * 1024) {
      throw ArgumentError('Ukuran foto maksimal 8 MB.');
    }

    // Struktur path: <rt_id>/<auth.uid>/<uuid>.<ext>
    final path = '$rtId/${user.id}/${_uuid.v4()}.$ext';
    await _bucket.upload(
      path,
      photo,
      fileOptions: FileOptions(contentType: mime, upsert: false),
    );
    return path;
  }

  Future<String> signedUrl(String path) =>
      _bucket.createSignedUrl(path, _urlTtlSeconds);

  Future<void> delete(String path) async {
    await _bucket.remove([path]);
  }
}
