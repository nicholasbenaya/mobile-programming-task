import '../constants/app_constants.dart';

class Validators {
  const Validators._();

  static String? title(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Judul wajib diisi';
    if (text.length > AppConstants.maxTitleLength) {
      return 'Maksimal ${AppConstants.maxTitleLength} karakter';
    }
    return null;
  }

  static String? note(String? value) {
    if ((value?.trim().length ?? 0) > AppConstants.maxNoteLength) {
      return 'Maksimal ${AppConstants.maxNoteLength} karakter';
    }
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Email wajib diisi';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) return 'Format email tidak valid';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password wajib diisi';
    if (value.length < 6) return 'Minimal 6 karakter';
    return null;
  }

  static String? fullName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Nama wajib diisi';
    if (text.length > 60) return 'Maksimal 60 karakter';
    return null;
  }
}
