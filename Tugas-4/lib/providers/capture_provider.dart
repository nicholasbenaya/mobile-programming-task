import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../core/errors/app_exception.dart';
import '../data/models/record_category.dart';
import '../data/models/record_draft.dart';
import '../data/models/record_model.dart';
import '../data/repositories/record_repository.dart';
import '../data/services/image_service.dart';
import '../data/services/location_service.dart';
import '../data/services/sensor_service.dart';

/// State layar "Catatan Baru": foto, lokasi, sensor langsung, dan proses simpan.
class CaptureProvider extends ChangeNotifier {
  CaptureProvider({
    required this.repository,
    required this.locationService,
    required this.sensorService,
    required this.imageService,
  });

  final RecordRepository repository;
  final LocationService locationService;
  final SensorService sensorService;
  final ImageService imageService;

  File? _photo;
  Position? _position;
  double? _compass;
  double? _tilt;
  double? _battery;
  bool _locating = false;
  bool _saving = false;
  bool _disposed = false;
  String? _locationError;
  String? _error;
  RecordCategory _category = RecordCategory.observasi;

  StreamSubscription<double>? _compassSub;
  StreamSubscription<double>? _tiltSub;

  File? get photo => _photo;
  Position? get position => _position;
  double? get compass => _compass;
  double? get tilt => _tilt;
  double? get battery => _battery;
  bool get locating => _locating;
  bool get saving => _saving;
  String? get locationError => _locationError;
  String? get error => _error;
  RecordCategory get category => _category;

  Future<void> start() async {
    _compassSub = sensorService.compassStream().listen((v) {
      if (_compass == null || (v - _compass!).abs() >= 2) {
        _compass = v;
        _notify();
      }
    });
    _tiltSub = sensorService.tiltStream().listen((v) {
      if (_tilt == null || (v - _tilt!).abs() >= 2) {
        _tilt = v;
        _notify();
      }
    });
    _battery = await sensorService.batteryLevel();
    _notify();
    await refreshLocation();
  }

  Future<void> refreshLocation() async {
    _locating = true;
    _locationError = null;
    _notify();
    try {
      _position = await locationService.current();
    } on AppException catch (e) {
      _locationError = e.message;
    } finally {
      _locating = false;
      _notify();
    }
  }

  Future<void> pickPhoto(ImageSource source) async {
    try {
      final file = await imageService.pick(source);
      if (file != null) {
        _photo = file;
        _error = null;
        _notify();
      }
    } on AppException catch (e) {
      _error = e.message;
      _notify();
    }
  }

  void removePhoto() {
    _photo = null;
    _notify();
  }

  void setCategory(RecordCategory value) {
    _category = value;
    _notify();
  }

  void clearError() => _error = null;

  /// Mengembalikan catatan tersimpan, atau null jika gagal ([error] berisi alasannya).
  Future<RecordModel?> submit({required String title, required String note}) async {
    if (_photo == null) {
      _error = 'Foto wajib diisi.';
      _notify();
      return null;
    }
    final position = _position;
    if (position == null) {
      _error = 'Lokasi belum tersedia. Tekan tombol segarkan lokasi.';
      _notify();
      return null;
    }

    _saving = true;
    _error = null;
    _notify();
    try {
      return await repository.create(
        RecordDraft(
          title: title,
          category: _category,
          note: note,
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          compass: _compass,
          tilt: _tilt,
          battery: _battery,
        ),
        _photo!,
      );
    } on AppException catch (e) {
      _error = e.message;
      return null;
    } finally {
      _saving = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _compassSub?.cancel();
    _tiltSub?.cancel();
    super.dispose();
  }
}
