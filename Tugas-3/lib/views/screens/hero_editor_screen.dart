import 'package:flutter/material.dart';

import '../../models/hero_model.dart';
import '../../utils/app_theme.dart';

class HeroEditorScreen extends StatefulWidget {
  final HeroModel? hero;

  const HeroEditorScreen({super.key, this.hero});

  bool get isEditing => hero != null;

  @override
  State<HeroEditorScreen> createState() => _HeroEditorScreenState();
}

class _HeroEditorScreenState extends State<HeroEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields;

  @override
  void initState() {
    super.initState();
    final hero = widget.hero;
    _fields = {
      'id': TextEditingController(text: hero?.id ?? ''),
      'name': TextEditingController(text: hero?.name ?? ''),
      'known_as': TextEditingController(text: hero?.knownAs ?? ''),
      'origin_city': TextEditingController(text: hero?.originCity ?? ''),
      'origin_province': TextEditingController(
        text: hero?.originProvince ?? '',
      ),
      'region_group': TextEditingController(text: hero?.regionGroup ?? ''),
      'birth_date': TextEditingController(text: hero?.birthDate ?? ''),
      'birth_place': TextEditingController(text: hero?.birthPlace ?? ''),
      'death_date': TextEditingController(text: hero?.deathDate ?? ''),
      'death_place': TextEditingController(text: hero?.deathPlace ?? ''),
      'age_at_death': TextEditingController(
        text: hero?.ageAtDeath.toString() ?? '',
      ),
      'photo_path': TextEditingController(
        text: hero?.photoPath ?? 'assets/images/',
      ),
      'short_bio': TextEditingController(text: hero?.shortBio ?? ''),
      'full_bio': TextEditingController(text: hero?.fullBio ?? ''),
      'struggle_era': TextEditingController(text: hero?.struggleEra ?? ''),
      'famous_quote': TextEditingController(text: hero?.famousQuote ?? ''),
      'quote_context': TextEditingController(text: hero?.quoteContext ?? ''),
      'decree_number': TextEditingController(text: hero?.decreeNumber ?? ''),
      'burial_place': TextEditingController(text: hero?.burialPlace ?? ''),
    };
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Wajib diisi' : null;

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final values = <String, String>{
      for (final entry in _fields.entries) entry.key: entry.value.text.trim(),
    };
    final age = int.tryParse(values['age_at_death'] ?? '');
    if (age == null || age < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usia wafat harus berupa angka yang valid.'),
        ),
      );
      return;
    }
    values['age_at_death'] = age.toString();
    Navigator.of(context).pop(values);
  }

  @override
  Widget build(BuildContext context) {
    final sections = [
      ('Identitas', ['id', 'name', 'known_as', 'photo_path']),
      (
        'Asal dan Masa Hidup',
        [
          'origin_city',
          'origin_province',
          'region_group',
          'birth_date',
          'birth_place',
          'death_date',
          'death_place',
          'age_at_death',
        ],
      ),
      (
        'Riwayat dan Penghormatan',
        [
          'short_bio',
          'full_bio',
          'struggle_era',
          'famous_quote',
          'quote_context',
          'decree_number',
          'burial_place',
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit Data Pahlawan' : 'Tambah Pahlawan',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text(
              widget.isEditing
                  ? 'Perbarui informasi pahlawan dari database.'
                  : 'Tambahkan data pahlawan baru ke database.',
              style: const TextStyle(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 20),
            for (final section in sections) ...[
              Text(
                section.$1,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.deepNavy,
                ),
              ),
              const SizedBox(height: 10),
              for (final field in section.$2) _buildField(field),
              const SizedBox(height: 14),
            ],
            ElevatedButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.save_rounded),
              label: Text(
                widget.isEditing ? 'Simpan Perubahan' : 'Simpan Pahlawan',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String name) {
    final labels = {
      'id': 'ID unik (contoh: cut_nyak_dhien)',
      'known_as': 'Dikenal sebagai',
      'origin_city': 'Kota asal',
      'origin_province': 'Provinsi asal',
      'region_group': 'Wilayah',
      'birth_date': 'Tanggal lahir',
      'birth_place': 'Tempat lahir',
      'death_date': 'Tanggal wafat',
      'death_place': 'Tempat wafat',
      'age_at_death': 'Usia wafat',
      'photo_path': 'Path foto asset',
      'short_bio': 'Biografi singkat',
      'full_bio': 'Biografi lengkap',
      'struggle_era': 'Era perjuangan',
      'famous_quote': 'Kutipan terkenal',
      'quote_context': 'Konteks kutipan',
      'decree_number': 'Nomor keputusan',
      'burial_place': 'Tempat persemayaman',
    };
    final multiline = {
      'short_bio',
      'full_bio',
      'famous_quote',
      'quote_context',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: _fields[name],
        enabled: !(widget.isEditing && name == 'id'),
        validator: _required,
        maxLines: multiline.contains(name) ? 4 : 1,
        keyboardType: name == 'age_at_death' ? TextInputType.number : null,
        decoration: InputDecoration(
          labelText: labels[name] ?? name,
          alignLabelWithHint: multiline.contains(name),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
