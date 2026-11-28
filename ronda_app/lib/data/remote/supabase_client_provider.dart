import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ronda_app/core/config/env.dart';
import 'package:ronda_app/core/errors/app_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Shared Riverpod provider exposing the initialized [SupabaseClient].
/// Override this provider in tests when substituting a fake/stub client.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  Env.ensureSupabaseConfigured();
  try {
    return Supabase.instance.client;
  } catch (error, stackTrace) {
    throw ConfigurationFailure(
      message:
          'Klien Supabase belum diinisialisasi. Pastikan aplikasi dimulai dengan konfigurasi env yang valid.',
      code: 'SUPABASE_NOT_INITIALIZED',
      cause: error,
      stackTrace: stackTrace,
    );
  }
});

/// Maps Supabase, PostgREST, and network exceptions into typed [AppFailure] values.
/// Handles PostgreSQL `P0002` (`no_data_found`) raised by custom SECURITY DEFINER RPCs.
AppFailure mapSupabaseError(Object error, [StackTrace? stackTrace]) {
  if (error is AppFailure) {
    return error;
  }
  if (error is PostgrestException && error.code == 'P0002') {
    return NotFoundFailure(
      message: error.message.isNotEmpty
          ? error.message
          : 'Data yang diminta tidak ditemukan.',
      code: 'P0002',
      cause: error,
      stackTrace: stackTrace,
    );
  }
  return AppFailure.fromException(error, stackTrace);
}
