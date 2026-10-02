import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/capture_provider.dart';
import 'widgets/detail_form_section.dart';
import 'widgets/photo_section.dart';
import 'widgets/sensor_section.dart';

/// Layar pembuatan catatan baru. Provider-nya hanya hidup selama layar ini terbuka.
class CaptureScreen extends StatelessWidget {
  const CaptureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CaptureProvider(
        repository: context.read(),
        locationService: context.read(),
        sensorService: context.read(),
        imageService: context.read(),
      )..start(),
      child: const _CaptureView(),
    );
  }
}

class _CaptureView extends StatefulWidget {
  const _CaptureView();

  @override
  State<_CaptureView> createState() => _CaptureViewState();
}

class _CaptureViewState extends State<_CaptureView> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final provider = context.read<CaptureProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;
    final record = await provider.submit(title: _title.text, note: _note.text);
    if (!mounted) return;
    if (record != null) {
      navigator.pop(record);
    } else if (provider.error != null) {
      messenger.showSnackBar(SnackBar(content: Text(provider.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = context.select<CaptureProvider, bool>((p) => p.saving);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Baru', style: TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: saving ? null : () => Navigator.of(context).pop()),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              const PhotoSection(),
              const SizedBox(height: 14),
              const SensorSection(),
              const SizedBox(height: 14),
              DetailFormSection(titleController: _title, noteController: _note),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton.icon(
          onPressed: saving ? null : _save,
          icon: saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5))
              : const Icon(Icons.check_rounded),
          label: Text(saving ? 'Menyimpan…' : 'Simpan catatan'),
        ),
      ),
    );
  }
}
