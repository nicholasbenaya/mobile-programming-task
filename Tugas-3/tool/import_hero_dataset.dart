import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const datasetUrl =
    'https://gist.githubusercontent.com/yuristianto/d2b2f75292927f15b633d9f8a3bd4ec6/raw/hero.json';

Future<void> main() async {
  final supabaseUrl = Platform.environment['SUPABASE_URL'];
  final serviceRoleKey = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'];
  if (supabaseUrl == null || serviceRoleKey == null) {
    stderr.writeln(
      'Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY before running this script.',
    );
    exitCode = 64;
    return;
  }

  final response = await http.get(Uri.parse(datasetUrl));
  if (response.statusCode != 200) {
    throw StateError('Dataset returned HTTP ${response.statusCode}.');
  }
  final decoded = jsonDecode(response.body);
  if (decoded is! List) {
    throw const FormatException('Dataset is not a JSON list.');
  }

  final rows = <Map<String, dynamic>>[];
  final contributions = <Map<String, dynamic>>[];
  for (var index = 0; index < decoded.length; index++) {
    final raw = Map<String, dynamic>.from(decoded[index] as Map);
    final name = _clean(raw['nama']);
    if (name.isEmpty) continue;
    final id = '${_slug(name)}_$index';
    final birth = _clean(raw['lahir']);
    final death = _clean(raw['gugur']);
    final history = _clean(raw['history']);
    final province = _clean(raw['asal']);
    final age = _parseAge(raw['usia']) ?? _age(birth, death);

    rows.add({
      'id': id,
      'sort_order': index,
      'name': name,
      'known_as': _clean(raw['nama2']).isEmpty ? name : _clean(raw['nama2']),
      'origin_city': _firstLocation(province),
      'origin_province': province.isEmpty ? 'Tidak diketahui' : province,
      'region_group': _region(province),
      'birth_date': birth.isEmpty ? 'Tidak diketahui' : birth,
      'birth_place': _locationAfterDate(birth),
      'death_date': death.isEmpty ? 'Tidak diketahui' : death,
      'death_place': _locationAfterDate(death),
      'age_at_death': age,
      'photo_path': _clean(raw['img']),
      'short_bio': _shorten(history),
      'full_bio': history.isEmpty ? 'Biografi belum tersedia.' : history,
      'struggle_era': _clean(raw['kategori']).isEmpty
          ? 'Pahlawan Nasional'
          : _clean(raw['kategori']),
      'famous_quote': _extractQuote(history),
      'quote_context': 'Kutipan atau ringkasan dari dataset hero.json',
      'decree_number': 'Data dataset hero.json',
      'burial_place': _clean(raw['lokasimakam']).isEmpty
          ? 'Tidak diketahui'
          : _clean(raw['lokasimakam']),
    });
    if (history.isNotEmpty) {
      contributions.add({
        'hero_id': id,
        'contribution': _shorten(history, maxLength: 500),
        'sort_order': 0,
      });
    }
  }

  final headers = {
    'apikey': serviceRoleKey,
    'Authorization': 'Bearer $serviceRoleKey',
    'Content-Type': 'application/json',
    'Prefer': 'resolution=merge-duplicates,return=minimal',
  };
  await _upsert('$supabaseUrl/rest/v1/heroes', rows, headers);
  await _upsert(
    '$supabaseUrl/rest/v1/hero_contributions',
    contributions,
    headers,
  );
  await _upsert(
    '$supabaseUrl/rest/v1/hero_contributions?on_conflict=hero_id,contribution',
    contributions,
    headers,
  );
  stdout.writeln(
    'Imported ${rows.length} heroes and ${contributions.length} biographies.',
  );
}

Future<void> _upsert(
  String url,
  List<Map<String, dynamic>> rows,
  Map<String, String> headers,
) async {
  for (var start = 0; start < rows.length; start += 100) {
    final end = (start + 100).clamp(0, rows.length);
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(rows.sublist(start, end)),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Import failed (${response.statusCode}): ${response.body}',
      );
    }
    stdout.writeln('Uploaded $end/${rows.length} rows to $url');
  }
}

String _clean(dynamic value) =>
    value?.toString().replaceAll(RegExp(r'\s+'), ' ').trim() ?? '';

String _slug(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
    .replaceAll(RegExp(r'^_|_$'), '');

int? _parseAge(dynamic value) =>
    int.tryParse(_clean(value).replaceAll(RegExp(r'[^0-9]'), ''));

int _age(String birth, String death) {
  final birthYear = _year(birth);
  final deathYear = _year(death);
  return birthYear != null && deathYear != null && deathYear >= birthYear
      ? deathYear - birthYear
      : 0;
}

int? _year(String value) =>
    RegExp(r'\b(1[5-9]\d{2}|20\d{2})\b')
        .firstMatch(value)
        ?.group(1)
        .let(int.parse);

String _locationAfterDate(String value) {
  final parts = value.split(RegExp(r'\s+di\s+', caseSensitive: false));
  return parts.length > 1 ? parts.last : 'Tidak diketahui';
}

String _firstLocation(String value) => value.split(',').first.trim();

String _region(String province) {
  final value = province.toLowerCase();
  if (value.contains('jawa') ||
      value.contains('yogyakarta') ||
      value.contains('banten')) {
    return 'Jawa';
  }
  if (value.contains('sumatera') ||
      value.contains('aceh') ||
      value.contains('lampung') ||
      value.contains('riau')) {
    return 'Sumatera';
  }
  if (value.contains('sulawesi')) return 'Sulawesi';
  if (value.contains('maluku')) return 'Maluku';
  if (value.contains('papua')) return 'Papua';
  if (value.contains('bali') || value.contains('nusa')) return 'Bali & Nusa';
  return 'Kalimantan';
}

String _shorten(String value, {int maxLength = 240}) =>
    value.length <= maxLength
    ? value
    : '${value.substring(0, maxLength).trim()}...';

String _extractQuote(String value) {
  final match = RegExp(r'''["“”']([^"“”']{20,180})["“”']''').firstMatch(value);
  return match?.group(1) ?? 'Kutipan belum tersedia dalam dataset.';
}

extension on String? {
  T? let<T>(T Function(String value) transform) =>
      this == null ? null : transform(this!);
}
