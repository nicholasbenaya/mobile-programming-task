import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/record_model.dart';
import '../../providers/records_provider.dart';
import '../screens/capture/capture_screen.dart';
import '../screens/detail/record_detail_screen.dart';

/// Semua perpindahan layar lewat sini supaya mudah dilacak dan diubah.
class AppRoutes {
  const AppRoutes._();

  static Future<void> openDetail(BuildContext context, RecordModel record) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => RecordDetailScreen(record: record)),
    );
  }

  static Future<void> openCapture(BuildContext context) async {
    final records = context.read<RecordsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final saved = await Navigator.of(context).push<RecordModel>(
      MaterialPageRoute<RecordModel>(fullscreenDialog: true, builder: (_) => const CaptureScreen()),
    );
    if (saved != null) {
      records.addLocal(saved);
      messenger.showSnackBar(const SnackBar(content: Text('Catatan berhasil disimpan')));
    }
  }
}
