import 'dart:io';

import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> pick(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      if (picked == null) return null;
      final file = File(picked.path);
      if (await file.length() > AppConstants.maxImageBytes) {
        throw const AppException('Ukuran foto maksimal 8 MB.');
      }
      return file;
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException('Tidak dapat mengakses kamera atau galeri.');
    }
  }
}
