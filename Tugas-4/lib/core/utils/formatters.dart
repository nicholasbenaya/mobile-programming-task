import 'package:intl/intl.dart';

class Formatters {
  const Formatters._();

  static String dateTime(DateTime date) =>
      DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(date.toLocal());

  static String shortDate(DateTime date) =>
      DateFormat('d MMM yyyy', 'id_ID').format(date.toLocal());

  static String coordinates(double lat, double lng) =>
      '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';

  static String degrees(double? value) =>
      value == null ? '—' : '${value.toStringAsFixed(0)}°';

  static String percent(double? value) =>
      value == null ? '—' : '${value.toStringAsFixed(0)}%';

  static String meters(double? value) =>
      value == null ? '—' : '±${value.toStringAsFixed(0)} m';

  /// Arah mata angin (singkatan Indonesia): U, TL, T, TG, S, BD, B, BL.
  static String compassLabel(double degrees) {
    const labels = ['U', 'TL', 'T', 'TG', 'S', 'BD', 'B', 'BL'];
    final normalized = ((degrees % 360) + 360) % 360;
    return labels[((normalized + 22.5) % 360 / 45).floor()];
  }
}
