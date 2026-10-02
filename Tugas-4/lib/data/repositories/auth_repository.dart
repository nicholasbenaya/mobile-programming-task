import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';

/// Semua urusan akun (daftar, masuk, Google, keluar) lewat sini.
class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;
  GoTrueClient get _auth => _client.auth;

  User? get currentUser => _auth.currentUser;
  Stream<AuthState> get authChanges => _auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String name,
    required String email,
    required String password,
  }) {
    return _guard(() async {
      final res = await _auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': name.trim()},
        emailRedirectTo: kIsWeb ? null : AppConstants.authRedirectUrl,
      );
      // Jika "Confirm email" aktif, email yang sudah terdaftar tidak memberi error
      // tetapi mengembalikan user tanpa identities.
      final identities = res.user?.identities;
      if (res.user != null && identities != null && identities.isEmpty) {
        throw const AppException('Email ini sudah terdaftar. Silakan masuk.');
      }
      return res;
    });
  }

  Future<void> signInWithEmail({required String email, required String password}) {
    return _guard(() async {
      await _auth.signInWithPassword(email: email.trim(), password: password);
    });
  }

  /// Membuka halaman login Google. Sesi masuk lewat [authChanges] setelah kembali ke aplikasi.
  Future<void> signInWithGoogle() {
    return _guard(() async {
      await _auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : AppConstants.authRedirectUrl,
      );
    });
  }

  Future<void> signOut() => _guard(() => _auth.signOut());

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AppException {
      rethrow;
    } on AuthException catch (e) {
      throw AppException(_message(e));
    } on SocketException {
      throw const AppException('Tidak ada koneksi internet.');
    } catch (_) {
      throw const AppException('Terjadi kesalahan. Coba lagi.');
    }
  }

  String _message(AuthException e) {
    final m = e.message.toLowerCase();
    if (m.contains('invalid login credentials')) return 'Email atau password salah.';
    if (m.contains('email not confirmed')) return 'Email belum diverifikasi. Cek kotak masuk Anda.';
    if (m.contains('already registered') || m.contains('already been registered')) {
      return 'Email ini sudah terdaftar. Silakan masuk.';
    }
    if (m.contains('password should be') || m.contains('weak password')) {
      return 'Password terlalu lemah (minimal 6 karakter).';
    }
    if (m.contains('rate limit') || '${e.statusCode}' == '429') {
      return 'Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi.';
    }
    if (m.contains('provider is not enabled') || m.contains('unsupported provider')) {
      return 'Login Google belum diaktifkan di Supabase.';
    }
    if (m.contains('signups not allowed')) return 'Pendaftaran akun baru dinonaktifkan.';
    return 'Autentikasi gagal. Periksa data Anda lalu coba lagi.';
  }
}
