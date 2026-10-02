import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/record_model.dart';

class ExportService {
  static const _headers = [
    'id', 'created_at', 'title', 'category', 'note', 'latitude', 'longitude',
    'accuracy', 'compass', 'tilt', 'battery', 'photo_path',
  ];

  String buildCsv(List<RecordModel> records) {
    final rows = <List<Object?>>[
      _headers,
      for (final r in records)
        [
          r.id, r.createdAt.toUtc().toIso8601String(), r.title, r.category.name, r.note,
          r.latitude, r.longitude, r.accuracy, r.compass, r.tilt, r.battery, r.photoPath,
        ],
    ];
    // BOM supaya Excel membaca UTF-8 dengan benar.
    return '\ufeff${rows.map((row) => row.map(_escape).join(',')).join('\n')}';
  }

  Future<void> shareCsv(List<RecordModel> records) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/sensorlog_export.csv');
    await file.writeAsString(buildCsv(records));
    await Share.shareXFiles([XFile(file.path, mimeType: 'text/csv')], subject: 'Ekspor SensorLog');
  }

  String _escape(Object? value) {
    final text = value?.toString() ?? '';
    if (text.contains(RegExp(r'[",\n\r]'))) {
      return '"${text.replaceAll('"', '""')}"';
    }
    return text;
  }
}
