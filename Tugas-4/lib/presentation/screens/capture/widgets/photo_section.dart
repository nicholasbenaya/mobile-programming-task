import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../providers/capture_provider.dart';
import '../../../widgets/section_card.dart';

class PhotoSection extends StatelessWidget {
  const PhotoSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CaptureProvider>();
    final scheme = Theme.of(context).colorScheme;
    final photo = provider.photo;

    return SectionCard(
      step: 1,
      title: 'Foto',
      child: photo == null
          ? Column(
              children: [
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_camera_back_rounded, size: 44, color: scheme.outline),
                      const SizedBox(height: 8),
                      Text('Belum ada foto', style: TextStyle(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                        onPressed: () => provider.pickPhoto(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera_rounded),
                        label: const Text('Kamera'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                        onPressed: () => provider.pickPhoto(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_rounded),
                        label: const Text('Galeri'),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(photo, height: 220, width: double.infinity, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      IconButton.filled(
                        tooltip: 'Ambil ulang',
                        onPressed: () => provider.pickPhoto(ImageSource.camera),
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                      const SizedBox(width: 6),
                      IconButton.filled(
                        tooltip: 'Hapus foto',
                        onPressed: provider.removePhoto,
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
