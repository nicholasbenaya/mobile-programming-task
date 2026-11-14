import 'record_category.dart';

/// Data catatan baru sebelum dikirim ke Supabase.
class RecordDraft {
  const RecordDraft({
    required this.title,
    required this.category,
    required this.note,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.compass,
    this.tilt,
    this.battery,
  });

  final String title;
  final RecordCategory category;
  final String note;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? compass;
  final double? tilt;
  final double? battery;

  Map<String, dynamic> toInsertMap(String photoPath) => {
        'title': title.trim(),
        'category': category.name,
        'note': note.trim(),
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'compass': compass,
        'tilt': tilt,
        'battery': battery,
        'photo_path': photoPath,
      };
}
