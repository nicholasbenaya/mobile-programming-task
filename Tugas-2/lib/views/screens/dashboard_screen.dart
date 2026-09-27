import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/pahlawan_controller.dart';
import '../../utils/app_theme.dart';
import 'hero_detail_screen.dart';

/// Dashboard versi baru.
/// Parameter dan API controller sama dengan DashboardScreen lama,
/// jadi cukup ganti pemanggilnya di navigasi tab.
class DashboardScreen extends StatelessWidget {
  final Function(int)? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PahlawanController>();
    final featured = controller.featuredHero;

    return Scaffold(
      body: RefreshIndicator(
        edgeOffset: MediaQuery.of(context).padding.top + 40,
        onRefresh: () async => controller.resetFilters(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _Header(controller: controller, onNavigateTab: onNavigateTab)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 26, 18, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const _SectionTitle('Pahlawan hari ini'),
                  const SizedBox(height: 12),
                  _FeaturedHero(featured: featured),
                  const SizedBox(height: 28),
                  const _SectionTitle('Jelajahi aplikasi'),
                  const SizedBox(height: 12),
                  _ShortcutList(onNavigateTab: onNavigateTab),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header: judul + ringkasan angka dalam satu strip
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  final PahlawanController controller;
  final Function(int)? onNavigateTab;

  const _Header({required this.controller, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(20, topInset + 18, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.deepNavy, Color(0xFF2A1E3A), AppTheme.primaryRed],
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          // Satu lingkaran dekoratif saja, sengaja dibuat samar.
          Positioned(
            right: -60,
            top: -50,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.flag_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Pahlawan Nasional',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const Text(
                'Kenali mereka yang\nmemperjuangkan Indonesia.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Baca biodata, lihat foto, lalu uji pengetahuanmu.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 22),
              _StatStrip(controller: controller, onNavigateTab: onNavigateTab),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatStrip extends StatelessWidget {
  final PahlawanController controller;
  final Function(int)? onNavigateTab;

  const _StatStrip({required this.controller, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatData('Pahlawan', '${controller.totalHeroes}', Icons.people_alt_rounded, 1),
      _StatData('Wilayah', '${controller.totalRegions}', Icons.map_rounded, 2),
      _StatData('Foto', '15', Icons.photo_library_rounded, 2),
      _StatData('Favorit', '${controller.totalFavorites}', Icons.bookmark_rounded, 1),
    ];

    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) {
        children.add(Container(
          width: 1,
          height: 34,
          color: Colors.white.withValues(alpha: 0.18),
        ));
      }
      children.add(Expanded(
        child: _StatItem(data: items[i], onTap: () => onNavigateTab?.call(items[i].tab)),
      ));
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(children: children),
    );
  }
}

class _StatData {
  final String label;
  final String value;
  final IconData icon;
  final int tab;
  const _StatData(this.label, this.value, this.icon, this.tab);
}

class _StatItem extends StatelessWidget {
  final _StatData data;
  final VoidCallback onTap;

  const _StatItem({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(data.icon, size: 16, color: AppTheme.warmAmber),
            const SizedBox(height: 6),
            Text(
              data.value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              data.label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pahlawan hari ini: satu elemen utama, foto penuh dengan teks di atasnya
// ---------------------------------------------------------------------------

class _FeaturedHero extends StatelessWidget {
  final dynamic featured;

  const _FeaturedHero({required this.featured});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepNavy.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Material(
          color: AppTheme.deepNavy,
          child: InkWell(
            onTap: () => Navigator.of(context).push(HeroDetailScreen.route(featured)),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  featured.photoPath,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.person, size: 72, color: Colors.white),
                  ),
                ),
                // Gradasi supaya teks tetap terbaca di atas foto apa pun.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppTheme.deepNavy.withValues(alpha: 0.55),
                        AppTheme.deepNavy.withValues(alpha: 0.95),
                      ],
                      stops: const [0.35, 0.65, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRed,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      featured.struggleEra,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        featured.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        featured.knownAs,
                        style: const TextStyle(
                          color: AppTheme.warmAmber,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        featured.shortBio,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Icon(Icons.history_rounded,
                              size: 15, color: Colors.white.withValues(alpha: 0.7)),
                          const SizedBox(width: 6),
                          Text(
                            featured.lifeTimeYears,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Buka detail',
                                  style: TextStyle(
                                    color: AppTheme.primaryRed,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward_rounded,
                                    size: 14, color: AppTheme.primaryRed),
                              ],
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
}

// ---------------------------------------------------------------------------
// Pintasan: satu daftar bergaris, bukan kartu-kartu identik
// ---------------------------------------------------------------------------

class _ShortcutList extends StatelessWidget {
  final Function(int)? onNavigateTab;

  const _ShortcutList({this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final items = [
      _ShortcutData('Daftar pahlawan', '15 pahlawan beserta biodata', Icons.list_alt_rounded,
          AppTheme.primaryRed, 1),
      _ShortcutData('Galeri foto', 'Lihat foto dalam grid, bisa di-zoom', Icons.grid_view_rounded,
          AppTheme.warmAmber, 2),
      _ShortcutData('Kuis sejarah', 'Uji seberapa kamu mengenal mereka', Icons.quiz_rounded,
          Colors.blue.shade700, 3),
    ];

    final rows = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) {
        rows.add(Divider(height: 1, indent: 76, color: Colors.grey.shade200));
      }
      rows.add(_ShortcutRow(
        data: items[i],
        onTap: () => onNavigateTab?.call(items[i].tab),
      ));
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          color: Colors.transparent,
          child: Column(children: rows),
        ),
      ),
    );
  }
}

class _ShortcutData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int tab;
  const _ShortcutData(this.title, this.subtitle, this.icon, this.color, this.tab);
}

class _ShortcutRow extends StatelessWidget {
  final _ShortcutData data;
  final VoidCallback onTap;

  const _ShortcutRow({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(data.icon, color: data.color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.deepNavy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.subtitle,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppTheme.primaryRed,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppTheme.deepNavy,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}