import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/errors/app_exception.dart';
import '../data/repositories/auth_repository.dart';

enum SignUpOutcome { signedIn, needsEmailConfirmation, failed }

/// State akun: siapa yang sedang masuk, proses masuk/daftar, dan pesan error.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repository) : _user = _repository.currentUser {
    _sub = _repository.authChanges.listen((state) {
      _user = state.session?.user;
      _notify();
    }, onError: (_) {});
  }

  final AuthRepository _repository;
  StreamSubscription<AuthState>? _sub;
  User? _user;
  bool _loading = false;
  bool _disposed = false;
  String? _error;

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get loading => _loading;
  String? get error => _error;

  String get email => _user?.email ?? '';

  String get displayName {
    final meta = _user?.userMetadata;
    final name = (meta?['full_name'] ?? meta?['name']) as String?;
    if (name != null && name.trim().isNotEmpty) return name.trim();
    if (email.contains('@')) return email.split('@').first;
    return 'Pengguna';
  }

  String? get avatarUrl {
    final meta = _user?.userMetadata;
    return (meta?['avatar_url'] ?? meta?['picture']) as String?;
  }

  String get providerLabel => _user?.appMetadata['provider'] == 'google' ? 'Google' : 'Email';

  DateTime? get joinedAt => DateTime.tryParse(_user?.createdAt ?? '');

  Future<bool> signIn({required String email, required String password}) {
    return _run(() => _repository.signInWithEmail(email: email, password: password));
  }

  Future<bool> signInWithGoogle() => _run(_repository.signInWithGoogle);

  Future<SignUpOutcome> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    _begin();
    try {
      final res = await _repository.signUp(name: name, email: email, password: password);
      return res.session != null ? SignUpOutcome.signedIn : SignUpOutcome.needsEmailConfirmation;
    } on AppException catch (e) {
      _error = e.message;
      return SignUpOutcome.failed;
    } finally {
      _loading = false;
      _notify();
    }
  }

  Future<void> signOut() async {
    try {
      await _repository.signOut();
    } on AppException catch (e) {
      _error = e.message;
      _notify();
    }
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      _notify();
    }
  }

  Future<bool> _run(Future<void> Function() action) async {
    _begin();
    try {
      await action();
      return true;
    } on AppException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _loading = false;
      _notify();
    }
  }

  void _begin() {
    _loading = true;
    _error = null;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    super.dispose();
  }
}
