import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../providers/capture_provider.dart';
import '../../widgets/motion/fade_in_slide.dart';
import '../../widgets/motion/loading_button.dart';
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
  bool _done = false;

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

    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }
    final record = await provider.submit(title: _title.text, note: _note.text);
    if (!mounted) return;
    if (record != null) {
      HapticFeedback.mediumImpact();
      setState(() => _done = true); // tampilkan animasi sukses sebelum menutup layar
      await Future<void>.delayed(const Duration(milliseconds: 950));
      if (mounted) navigator.pop(record);
    } else if (provider.error != null) {
      HapticFeedback.heavyImpact();
      messenger.showSnackBar(SnackBar(content: Text(provider.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = context.select<CaptureProvider, bool>((p) => p.saving);
    final busy = saving || _done;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Baru', style: TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: busy ? null : () => Navigator.of(context).pop()),
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: staggered(
                  [
                    const PhotoSection(),
                    const SizedBox(height: 14),
                    const SensorSection(),
                    const SizedBox(height: 14),
                    DetailFormSection(titleController: _title, noteController: _note),
                  ],
                  stepMs: 90,
                ),
              ),
            ),
          ),
          if (_done) const Positioned.fill(child: _SuccessOverlay()),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: LoadingButton(
          loading: saving,
          icon: Icons.check_rounded,
          label: 'Simpan catatan',
          onPressed: busy ? null : _save,
        ),
      ),
    );
  }
}

/// Animasi centang "Tersimpan!" setelah catatan berhasil dikirim.
class _SuccessOverlay extends StatelessWidget {
  const _SuccessOverlay();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 250),
      builder: (_, t, child) => Opacity(opacity: t, child: child),
      child: ColoredBox(
        color: scheme.surface.withValues(alpha: 0.96),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PopIn(
                delay: const Duration(milliseconds: 120),
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primary,
                    boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: 0.35), blurRadius: 28, spreadRadius: 2)],
                  ),
                  child: Icon(Icons.check_rounded, size: 62, color: scheme.onPrimary),
                ),
              ),
              const SizedBox(height: 22),
              FadeInSlide(
                delay: const Duration(milliseconds: 300),
                child: Text('Tersimpan!', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
