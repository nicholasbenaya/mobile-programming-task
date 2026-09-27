import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/pahlawan_controller.dart';
import '../../utils/app_theme.dart';
import '../widgets/gallery_card.dart';
import '../widgets/search_filter_bar.dart';

class HeroGalleryScreen extends StatefulWidget {
  const HeroGalleryScreen({super.key});

  @override
  State<HeroGalleryScreen> createState() => _HeroGalleryScreenState();
}

class _HeroGalleryScreenState extends State<HeroGalleryScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final controller = context.watch<PahlawanController>();
    final heroes = controller.filteredHeroes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Galeri Foto Pahlawan'),
      ),
      body: Column(
        children: [
          // Filter Chips Wilayah
          const SearchFilterBar(showFilterChips: true),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Row(
              children: [
                const Icon(Icons.photo_library_rounded, size: 16, color: AppTheme.primaryRed),
                const SizedBox(width: 6),
                Text(
                  'Koleksi Foto & Info Singkat (${heroes.length} Pahlawan)',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Grid Galeri (Mekanisme 3d)
          Expanded(
            child: heroes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.image_not_supported_outlined, size: 54, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text('Tidak ada foto pahlawan untuk kriteria ini'),
                      ],
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      // Responsif: 2 kolom untuk mobile, 3-4 kolom untuk layar lebar
                      final crossAxisCount = constraints.maxWidth > 900
                          ? 4
                          : constraints.maxWidth > 600
                              ? 3
                              : 2;

                      return GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                        ),
                        itemCount: heroes.length,
                        itemBuilder: (context, index) {
                          final hero = heroes[index];
                          return GalleryCard(hero: hero);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
