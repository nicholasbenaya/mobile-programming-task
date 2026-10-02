import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/record_category.dart';

/// Warna & ikon kategori dipisah dari model agar data layer bebas dari UI.
extension CategoryStyle on RecordCategory {
  Color get color => switch (this) {
        RecordCategory.observasi => AppColors.observasi,
        RecordCategory.lingkungan => AppColors.lingkungan,
        RecordCategory.infrastruktur => AppColors.infrastruktur,
        RecordCategory.lainnya => AppColors.lainnya,
      };

  IconData get icon => switch (this) {
        RecordCategory.observasi => Icons.visibility_rounded,
        RecordCategory.lingkungan => Icons.eco_rounded,
        RecordCategory.infrastruktur => Icons.construction_rounded,
        RecordCategory.lainnya => Icons.label_rounded,
      };
}
