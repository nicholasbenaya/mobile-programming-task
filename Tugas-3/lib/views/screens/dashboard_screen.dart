import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/pahlawan_controller.dart';
import '../../utils/app_theme.dart';
import '../../utils/hero_image.dart';
import '../widgets/stat_card.dart';
import 'hero_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int)? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PahlawanController>();
    final featured = controller.featuredHero;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryRed.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.flag_rounded,
                color: AppTheme.primaryRed,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Pahlawan Nasional'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          controller.resetFilters();
          // Tarik ke bawah = ambil ulang data terbaru dari server
          await controller.loadData(showLoading: false);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statistics Metrics
              const Text(
                'Ringkasan Data & Sejarah',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.deepNavy,
                ),
              ),
              const SizedBox(height: 12),
              _buildStatsGrid(context, controller),
              const SizedBox(height: 22),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pahlawan Hari Ini',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.deepNavy,
                    ),
                  ),
                  TextButton(
                    onPressed: () => onNavigateTab?.call(1),
                    child: const Text(
                      'Lihat Semua',
                      style: TextStyle(
                        color: AppTheme.primaryRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // featuredHero bisa null jika database kosong
              if (featured != null) _buildFeaturedCard(context, featured),
              const SizedBox(height: 22),

              // Navigasi Cepat / Menu Pintas
              const Text(
                'Jelajahi Fitur Aplikasi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.deepNavy,
                ),
              ),
              const SizedBox(height: 12),
              _buildQuickShortcuts(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, PahlawanController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 500;
        return GridView.count(
          crossAxisCount: isWide ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: isWide ? 1.6 : 1.7,
          children: [
            StatCard(
              title: 'Total Pahlawan',
              value: '${controller.totalHeroes}',
              icon: Icons.people_alt_rounded,
              color: AppTheme.primaryRed,
              onTap: () => onNavigateTab?.call(1),
            ),
            StatCard(
              title: 'Wilayah Asal',
              value: '${controller.totalRegions}',
              icon: Icons.map_rounded,
              color: AppTheme.warmAmber,
              onTap: () => onNavigateTab?.call(2),
            ),
            StatCard(
              title: 'Foto Galeri',
              value: '15',
              icon: Icons.photo_library_rounded,
              color: Colors.blue.shade700,
              onTap: () => onNavigateTab?.call(2),
            ),
            StatCard(
              title: 'Favorit Anda',
              value: '${controller.totalFavorites}',
              icon: Icons.bookmark_rounded,
              color: Colors.purple.shade700,
              onTap: () => onNavigateTab?.call(1),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeaturedCard(BuildContext context, dynamic featured) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.of(context).push(HeroDetailScreen.route(featured));
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: heroImage(
                    featured.photoPath,
                    width: 90,
                    height: 110,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 90,
                      height: 110,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.person, size: 40),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          featured.struggleEra,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryRed,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        featured.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.deepNavy,
                        ),
                      ),
                      Text(
                        featured.knownAs,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.warmAmber,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        featured.shortBio,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.history_rounded,
                            size: 14,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            featured.lifeTimeYears,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            'Buka Detail →',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryRed,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickShortcuts(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildShortcutButton(
            context,
            title: 'Daftar Pahlawan',
            subtitle: '15 Data & Biodata',
            icon: Icons.list_alt_rounded,
            color: AppTheme.primaryRed,
            onTap: () => onNavigateTab?.call(1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildShortcutButton(
            context,
            title: 'Galeri Foto',
            subtitle: 'Grid & Zoom Foto',
            icon: Icons.grid_view_rounded,
            color: AppTheme.warmAmber,
            onTap: () => onNavigateTab?.call(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildShortcutButton(
            context,
            title: 'Kuis Sejarah',
            subtitle: 'Uji Pengetahuan',
            icon: Icons.quiz_rounded,
            color: Colors.blue.shade700,
            onTap: () => onNavigateTab?.call(3),
          ),
        ),
      ],
    );
  }

  Widget _buildShortcutButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Column(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.deepNavy,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
