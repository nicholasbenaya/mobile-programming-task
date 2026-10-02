import 'record_category.dart';

/// Catatan lapangan yang sudah tersimpan di Supabase.
class RecordModel {
  const RecordModel({
    required this.id,
    required this.createdAt,
    required this.title,
    required this.category,
    required this.note,
    required this.latitude,
    required this.longitude,
    required this.photoPath,
    required this.photoUrl,
    this.accuracy,
    this.compass,
    this.tilt,
    this.battery,
  });

  final String id;
  final DateTime createdAt;
  final String title;
  final RecordCategory category;
  final String note;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? compass;
  final double? tilt;
  final double? battery;
  final String photoPath;
  final String photoUrl;

  factory RecordModel.fromMap(Map<String, dynamic> map, {required String photoUrl}) {
    return RecordModel(
      id: map['id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      title: map['title'] as String,
      category: RecordCategory.fromValue(map['category'] as String?),
      note: (map['note'] as String?) ?? '',
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      accuracy: _toDouble(map['accuracy']),
      compass: _toDouble(map['compass']),
      tilt: _toDouble(map['tilt']),
      battery: _toDouble(map['battery']),
      photoPath: map['photo_path'] as String,
      photoUrl: photoUrl,
    );
  }

  static double? _toDouble(Object? value) => value == null ? null : (value as num).toDouble();
}
