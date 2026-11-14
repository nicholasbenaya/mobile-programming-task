import 'package:geolocator/geolocator.dart';

import '../../core/errors/app_exception.dart';

class LocationService {
  Future<Position> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const AppException('GPS tidak aktif. Nyalakan lokasi di pengaturan HP.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const AppException('Izin lokasi ditolak.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw const AppException('Izin lokasi ditolak permanen. Ubah di pengaturan aplikasi.');
    }
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } catch (_) {
      throw const AppException('Gagal mendapatkan lokasi. Coba lagi di area terbuka.');
    }
  }
}
