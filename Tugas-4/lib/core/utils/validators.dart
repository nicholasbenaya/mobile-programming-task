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
}
