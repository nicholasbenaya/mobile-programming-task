import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/pahlawan_controller.dart';
import '../../utils/app_theme.dart';
import '../widgets/hero_card.dart';
import '../widgets/search_filter_bar.dart';
import 'hero_list_screen_other.dart';
import 'hero_admin_screen.dart';

class HeroListScreen extends StatefulWidget {
  const HeroListScreen({super.key});

  @override
  State<HeroListScreen> createState() => _HeroListScreenState();
}

class _HeroListScreenState extends State<HeroListScreen> {
  bool _isCatalogView = false;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PahlawanController>();
    final heroes = controller.filteredHeroes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Pahlawan Nasional'),
        actions: [
          IconButton(
            tooltip: 'Kelola data pahlawan',
            icon: const Icon(Icons.admin_panel_settings_outlined),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const HeroAdminScreen())),
          ),
          if (controller.searchQuery.isNotEmpty ||
              controller.selectedRegion != 'Semua' ||
              controller.selectedEra != 'Semua')
            TextButton.icon(
              onPressed: () => controller.resetFilters(),
              icon: const Icon(
                Icons.refresh_rounded,
                size: 16,
                color: AppTheme.primaryRed,
              ),
              label: const Text(
                'Reset',
                style: TextStyle(
                  color: AppTheme.primaryRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          const SearchFilterBar(),

          // Info Jumlah Hasil + Switch Katalog
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 12, 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Menampilkan ${heroes.length} dari ${controller.allHeroes.length} Pahlawan',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      if (controller.selectedRegion != 'Semua')
                        Text(
                          'Wilayah: ${controller.selectedRegion}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryRed,
                          ),
                        ),
                    ],
                  ),
                ),
                const Text(
                  'View Katalog',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
                  ),
                ),
                Switch(
                  value: _isCatalogView,
                  activeColor: AppTheme.primaryRed,
                  onChanged: (value) => setState(() => _isCatalogView = value),
                ),
              ],
            ),
          ),

          // Konten: List (default) atau Katalog
          Expanded(
            child: heroes.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Pahlawan Tidak Ditemukan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Coba ubah kata kunci pencarian atau reset filter wilayah Anda.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryRed,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => controller.resetFilters(),
                            child: const Text('Reset Filter'),
                          ),
                        ],
                      ),
                    ),
                  )
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _isCatalogView
                        ? HeroListScreenOther(
                            key: const ValueKey('catalog'),
                            heroes: heroes,
                          )
                        : ListView.builder(
                            key: const ValueKey('list'),
                            padding: const EdgeInsets.only(top: 4, bottom: 24),
                            itemCount: heroes.length,
                            itemBuilder: (context, index) {
                              return HeroCard(hero: heroes[index]);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
