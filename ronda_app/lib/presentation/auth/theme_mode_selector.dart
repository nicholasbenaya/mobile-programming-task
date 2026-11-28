import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ronda_app/core/theme/civic_tokens.dart';
import 'package:ronda_app/providers/theme_provider.dart';

/// Compact 3-state theme selector (System, Light, Dark) wired to [themeModeProvider].
class ThemeModeSelector extends ConsumerWidget {
  const ThemeModeSelector({super.key, this.showIcons = true});

  final bool showIcons;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(themeModeProvider);
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<ThemeMode>(
        showSelectedIcon: false,
        segments: <ButtonSegment<ThemeMode>>[
          ButtonSegment<ThemeMode>(
            value: ThemeMode.system,
            label: const Text('Sistem'),
            icon: showIcons ? const Icon(Icons.brightness_auto_outlined) : null,
          ),
          ButtonSegment<ThemeMode>(
            value: ThemeMode.light,
            label: const Text('Terang'),
            icon: showIcons ? const Icon(Icons.light_mode_outlined) : null,
          ),
          ButtonSegment<ThemeMode>(
            value: ThemeMode.dark,
            label: const Text('Gelap'),
            icon: showIcons ? const Icon(Icons.dark_mode_outlined) : null,
          ),
        ],
        selected: <ThemeMode>{currentMode},
        onSelectionChanged: (selection) {
          ref.read(themeModeProvider.notifier).setThemeMode(selection.first);
        },
      ),
    );
  }
}

/// Framed card version of [ThemeModeSelector] for settings and profile panels.
class ThemeModeSelectorCard extends StatelessWidget {
  const ThemeModeSelectorCard({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(CivicTokens.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mode Tampilan', style: textTheme.titleMedium),
            const SizedBox(height: CivicTokens.spaceXs),
            Text(
              'Pilih tampilan siang atau malam sesuai kebutuhan jaga.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: CivicTokens.spaceMd),
            const ThemeModeSelector(),
          ],
        ),
      ),
    );
  }
}
