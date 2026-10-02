import 'package:latlong2/latlong.dart';

class AppConstants {
  const AppConstants._();

  static const appName = 'SensorLog';
  static const maxImageBytes = 8 * 1024 * 1024;
  static const maxTitleLength = 100;
  static const maxNoteLength = 1000;
  static const photoBucket = 'record-photos';
  static const recordsTable = 'records';
  static const mapUserAgent = 'id.sensorlog.app';
  static const mapTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const defaultMapCenter = LatLng(-2.5, 118.0); // tengah Indonesia
}
