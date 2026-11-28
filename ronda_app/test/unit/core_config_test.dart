import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ronda_app/core/config/env.dart';
import 'package:ronda_app/core/errors/app_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('Env', () {
    test('uses expected Android SOS notification channel id', () {
      expect(Env.sosNotificationChannelId, 'rondadigital_sos_alarm');
    });

    test('accepts valid https and http Supabase configurations', () {
      expect(
        Env.isValidSupabaseConfig(
          url: 'https://example.supabase.co',
          anonKey: 'test-anon-key',
        ),
        isTrue,
      );
      expect(
        Env.isValidSupabaseConfig(
          url: 'http://127.0.0.1:54321',
          anonKey: 'local-anon-key',
        ),
        isTrue,
      );
    });

    test('rejects missing or malformed Supabase configurations', () {
      expect(
        Env.isValidSupabaseConfig(url: '', anonKey: 'key'),
        isFalse,
      );
      expect(
        Env.isValidSupabaseConfig(url: 'https://example.supabase.co', anonKey: '   '),
        isFalse,
      );
      expect(
        Env.isValidSupabaseConfig(url: 'ftp://example.supabase.co', anonKey: 'key'),
        isFalse,
      );
      expect(
        Env.isValidSupabaseConfig(url: 'not-a-url', anonKey: 'key'),
        isFalse,
      );
    });

    test('ensureSupabaseConfigured throws ConfigurationFailure for invalid values', () {
      expect(
        () => Env.ensureSupabaseConfigured(url: '', anonKey: ''),
        throwsA(
          isA<ConfigurationFailure>()
              .having((f) => f.code, 'code', 'ENV_MISSING')
              .having((f) => f.message, 'message', contains('SUPABASE_URL'))
              .having((f) => f.message, 'message', contains('SUPABASE_ANON_KEY')),
        ),
      );

      expect(
        () => Env.ensureSupabaseConfigured(url: 'invalid-url', anonKey: 'key'),
        throwsA(
          isA<ConfigurationFailure>().having((f) => f.code, 'code', 'ENV_INVALID_URL'),
        ),
      );

      expect(
        () => Env.ensureSupabaseConfigured(
          url: 'https://example.supabase.co',
          anonKey: 'valid-key',
        ),
        returnsNormally,
      );
    });
  });

  group('AppFailure.fromException', () {
    test('returns existing AppFailure unchanged', () {
      const original = ValidationFailure(
        message: 'Catatan audit minimal 5 karakter.',
        fieldErrors: {'reviewNote': 'Terlalu pendek'},
      );
      expect(AppFailure.fromException(original), same(original));
    });

    test('maps network and timeout errors to NetworkFailure', () {
      final offline = AppFailure.fromException(const SocketException('No route'));
      expect(offline, isA<NetworkFailure>());
      expect(offline.code, 'NETWORK_OFFLINE');

      final timeout = AppFailure.fromException(TimeoutException('Timed out'));
      expect(timeout, isA<NetworkFailure>());
      expect(timeout.code, 'NETWORK_TIMEOUT');
    });

    test('maps Supabase AuthException and StorageException appropriately', () {
      final authForbidden = AppFailure.fromException(
        const AuthException('Forbidden', statusCode: '403'),
      );
      expect(authForbidden, isA<PermissionFailure>());

      final authError = AppFailure.fromException(
        const AuthException('Invalid login credentials', statusCode: '400'),
      );
      expect(authError, isA<AuthFailure>());

      final storageForbidden = AppFailure.fromException(
        const StorageException('Forbidden', statusCode: '403'),
      );
      expect(storageForbidden, isA<PermissionFailure>());

      final storageNotFound = AppFailure.fromException(
        const StorageException('Not found', statusCode: '404'),
      );
      expect(storageNotFound, isA<NotFoundFailure>());

      final storageOther = AppFailure.fromException(
        const StorageException('Upload failed', statusCode: '500'),
      );
      expect(storageOther, isA<StorageFailure>());
    });

    test('maps PostgrestException SQLSTATE codes to semantic failures', () {
      expect(
        AppFailure.fromException(
          const PostgrestException(message: 'RLS denied', code: '42501'),
        ),
        isA<PermissionFailure>(),
      );
      expect(
        AppFailure.fromException(
          const PostgrestException(message: 'Duplicate pending swap', code: '23505'),
        ),
        isA<ConflictFailure>(),
      );
      expect(
        AppFailure.fromException(
          const PostgrestException(message: 'No rows', code: 'PGRST116'),
        ),
        isA<NotFoundFailure>(),
      );
      expect(
        AppFailure.fromException(
          const PostgrestException(message: 'Check failed', code: '23514'),
        ),
        isA<ValidationFailure>(),
      );
      expect(
        AppFailure.fromException(
          const PostgrestException(message: 'Internal error', code: 'XX000'),
        ),
        isA<ServerFailure>(),
      );
    });

    test('maps FunctionException, FormatException, and unknown errors', () {
      final fnError = AppFailure.fromException(
        const FunctionException(status: 502, details: 'FCM unavailable'),
      );
      expect(
        fnError,
        isA<ServerFailure>().having((f) => f.statusCode, 'statusCode', 502),
      );

      final formatError = AppFailure.fromException(
        const FormatException('Format QR tidak dikenali'),
      );
      expect(formatError, isA<ValidationFailure>());

      final unknown = AppFailure.fromException(StateError('unexpected'));
      expect(unknown, isA<UnexpectedFailure>());
    });

    test('supports exhaustive switch over sealed AppFailure subtypes', () {
      final samples = <AppFailure>[
        const ConfigurationFailure(message: 'cfg'),
        const NetworkFailure(message: 'net'),
        const AuthFailure(message: 'auth'),
        const PermissionFailure(message: 'perm'),
        const ValidationFailure(message: 'val'),
        const NotFoundFailure(message: 'nf'),
        const ConflictFailure(message: 'conf'),
        const StorageFailure(message: 'st'),
        const ServerFailure(message: 'srv'),
        const UnexpectedFailure(message: 'unk'),
      ];

      final labels = samples
          .map(
            (failure) => switch (failure) {
              ConfigurationFailure() => 'config',
              NetworkFailure() => 'network',
              AuthFailure() => 'auth',
              PermissionFailure() => 'permission',
              ValidationFailure() => 'validation',
              NotFoundFailure() => 'not_found',
              ConflictFailure() => 'conflict',
              StorageFailure() => 'storage',
              ServerFailure() => 'server',
              UnexpectedFailure() => 'unexpected',
            },
          )
          .toList();

      expect(labels, hasLength(10));
    });
  });
}
