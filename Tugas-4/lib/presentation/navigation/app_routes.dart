import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/models/record_model.dart';
import '../../providers/records_provider.dart';
import '../screens/account/account_screen.dart';
import '../screens/capture/capture_screen.dart';
import '../screens/detail/record_detail_screen.dart';
import 'app_transitions.dart';

/// Semua perpindahan layar lewat sini supaya mudah dilacak dan diubah.
class AppRoutes {
  const AppRoutes._();

  static Future<void> openDetail(BuildContext context, RecordModel record) {
    return Navigator.of(context).push(AppTransitions.route<void>(RecordDetailScreen(record: record)));
  }

  static Future<void> openAccount(BuildContext context) {
    return Navigator.of(context).push(AppTransitions.route<void>(const AccountScreen()));
  }

  static Future<void> openCapture(BuildContext context) async {
    final records = context.read<RecordsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    HapticFeedback.lightImpact();
    final saved = await Navigator.of(context).push<RecordModel>(
      AppTransitions.route<RecordModel>(const CaptureScreen(), style: RouteStyle.slideUp),
    );
    if (saved != null) {
      records.addLocal(saved);
      messenger.showSnackBar(const SnackBar(content: Text('Catatan berhasil disimpan')));
    }
  }
}
