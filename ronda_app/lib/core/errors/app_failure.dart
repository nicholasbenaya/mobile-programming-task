import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Base sealed failure type returned or thrown across repositories and services.
sealed class AppFailure implements Exception {
  const AppFailure({
    required this.message,
    required this.code,
    this.cause,
    this.stackTrace,
  });

  final String message;
  final String code;
  final Object? cause;
  final StackTrace? stackTrace;

  /// Maps raw platform, network, and Supabase exceptions into typed [AppFailure] values.
  static AppFailure fromException(Object error, [StackTrace? stackTrace]) {
    if (error is AppFailure) {
      return error;
    }

    if (error is SocketException) {
      return NetworkFailure(
        message:
            'Koneksi internet tidak tersedia. Periksa jaringan Anda lalu coba lagi.',
        code: 'NETWORK_OFFLINE',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (error is TimeoutException) {
      return NetworkFailure(
        message: 'Permintaan melebihi batas waktu. Coba beberapa saat lagi.',
        code: 'NETWORK_TIMEOUT',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (error is AuthException) {
      final statusCode = int.tryParse(error.statusCode ?? '');
      if (statusCode == 403) {
        return PermissionFailure(
          message: 'Akses ditolak untuk akun ini.',
          code: error.code ?? 'AUTH_FORBIDDEN',
          cause: error,
          stackTrace: stackTrace,
        );
      }
      return AuthFailure(
        message: error.message.isNotEmpty
            ? error.message
            : 'Autentikasi gagal. Periksa email dan kata sandi Anda.',
        code: error.code ?? 'AUTH_ERROR',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (error is StorageException) {
      final statusCode = int.tryParse(error.statusCode ?? '');
      if (statusCode == 403) {
        return PermissionFailure(
          message: 'Anda tidak memiliki izin mengakses berkas bukti ini.',
          code: 'STORAGE_FORBIDDEN',
          cause: error,
          stackTrace: stackTrace,
        );
      }
      if (statusCode == 404) {
        return NotFoundFailure(
          message: 'Berkas bukti tidak ditemukan.',
          code: 'STORAGE_NOT_FOUND',
          cause: error,
          stackTrace: stackTrace,
        );
      }
      return StorageFailure(
        message: error.message.isNotEmpty
            ? error.message
            : 'Gagal memproses berkas di penyimpanan.',
        code: 'STORAGE_ERROR',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (error is PostgrestException) {
      return _mapPostgrestException(error, stackTrace);
    }

    if (error is FunctionException) {
      return ServerFailure(
        message: 'Layanan server gagal memproses permintaan.',
        code: 'EDGE_FUNCTION_ERROR',
        statusCode: error.status,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (error is FormatException) {
      return ValidationFailure(
        message: error.message.isNotEmpty
            ? error.message
            : 'Format data tidak valid.',
        code: 'INVALID_FORMAT',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    return UnexpectedFailure(
      message: 'Terjadi kesalahan yang tidak terduga. Silakan coba lagi.',
      code: 'UNEXPECTED_ERROR',
      cause: error,
      stackTrace: stackTrace,
    );
  }

  static AppFailure _mapPostgrestException(
    PostgrestException error,
    StackTrace? stackTrace,
  ) {
    final code = error.code ?? 'POSTGREST_ERROR';
    // PostgreSQL SQLSTATE classes: 42501 insufficient privilege, 23505 unique violation,
    // 23514 check violation, 22xxx data exception, PGRST116 zero rows for single().
    if (code == '42501') {
      return PermissionFailure(
        message: 'Anda tidak memiliki izin untuk melakukan tindakan ini.',
        code: code,
        cause: error,
        stackTrace: stackTrace,
      );
    }
    if (code == '23505') {
      return ConflictFailure(
        message: error.message.isNotEmpty
            ? error.message
            : 'Data yang sama sudah terdaftar.',
        code: code,
        cause: error,
        stackTrace: stackTrace,
      );
    }
    if (code == 'PGRST116') {
      return NotFoundFailure(
        message: 'Data yang diminta tidak ditemukan.',
        code: code,
        cause: error,
        stackTrace: stackTrace,
      );
    }
    if (code == '23514' || code == '23502' || code.startsWith('22')) {
      return ValidationFailure(
        message: error.message.isNotEmpty
            ? error.message
            : 'Data tidak memenuhi aturan validasi.',
        code: code,
        cause: error,
        stackTrace: stackTrace,
      );
    }
    return ServerFailure(
      message: error.message.isNotEmpty
          ? error.message
          : 'Permintaan ke server database gagal.',
      code: code,
      cause: error,
      stackTrace: stackTrace,
    );
  }

  @override
  String toString() => '$runtimeType(code: $code, message: $message)';
}

final class ConfigurationFailure extends AppFailure {
  const ConfigurationFailure({
    required super.message,
    super.code = 'CONFIGURATION_ERROR',
    super.cause,
    super.stackTrace,
  });
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure({
    required super.message,
    super.code = 'NETWORK_ERROR',
    super.cause,
    super.stackTrace,
  });
}

final class AuthFailure extends AppFailure {
  const AuthFailure({
    required super.message,
    super.code = 'AUTH_ERROR',
    super.cause,
    super.stackTrace,
  });
}

final class PermissionFailure extends AppFailure {
  const PermissionFailure({
    required super.message,
    super.code = 'PERMISSION_DENIED',
    super.cause,
    super.stackTrace,
  });
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure({
    required super.message,
    super.code = 'VALIDATION_ERROR',
    this.fieldErrors = const <String, String>{},
    super.cause,
    super.stackTrace,
  });

  final Map<String, String> fieldErrors;
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure({
    required super.message,
    super.code = 'NOT_FOUND',
    super.cause,
    super.stackTrace,
  });
}

final class ConflictFailure extends AppFailure {
  const ConflictFailure({
    required super.message,
    super.code = 'CONFLICT',
    super.cause,
    super.stackTrace,
  });
}

final class StorageFailure extends AppFailure {
  const StorageFailure({
    required super.message,
    super.code = 'STORAGE_ERROR',
    super.cause,
    super.stackTrace,
  });
}

final class ServerFailure extends AppFailure {
  const ServerFailure({
    required super.message,
    super.code = 'SERVER_ERROR',
    this.statusCode,
    super.cause,
    super.stackTrace,
  });

  final int? statusCode;
}

final class UnexpectedFailure extends AppFailure {
  const UnexpectedFailure({
    required super.message,
    super.code = 'UNEXPECTED_ERROR',
    super.cause,
    super.stackTrace,
  });
}
