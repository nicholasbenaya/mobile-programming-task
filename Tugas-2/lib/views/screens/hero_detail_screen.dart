import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/hero_model.dart';
import '../../controllers/pahlawan_controller.dart';
import '../../utils/app_theme.dart';
import '../widgets/hero_photo_dialog.dart';

class HeroDetailScreen extends StatefulWidget {
  final HeroModel hero;

  const HeroDetailScreen({super.key, required this.hero});

  /// Helper untuk navigasi dengan transisi fluid yang mulus & dinamis
  static Route<void> route(HeroModel hero) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) =>
          HeroDetailScreen(hero: hero),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.06),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<HeroDetailScreen> createState() => _HeroDetailScreenState();
}

class _HeroDetailScreenState extends State<HeroDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  int _activeTabIndex =
      0; // 0: Linimasa & Data, 1: Kisah Biografi, 2: Jasa & Warisan
  int _saluteCount = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hero = widget.hero;
    final controller = context.watch<PahlawanController>();
    final isFav = controller.isFavorite(hero.id);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const ClampingScrollPhysics(), // Menghindari efek overscroll bounce yang memicu auto-zoom
            slivers: [
              // Header Elegan dengan Elemen Box Pembingkai Foto (Foto tidak ngezoom)
              SliverAppBar(
                expandedHeight: 410,
                pinned: true,
                elevation: 0,
                backgroundColor: const Color(0xFF650005),
                foregroundColor: Colors.white,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      tooltip: 'Kembali',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.photo_library_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        tooltip: 'Pratinjau Foto',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => HeroPhotoDialog(hero: hero),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 8.0,
                      bottom: 8.0,
                      right: 14.0,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, anim) =>
                              ScaleTransition(scale: anim, child: child),
                          child: Icon(
                            isFav
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            key: ValueKey<bool>(isFav),
                            color: isFav ? AppTheme.accentGold : Colors.white,
                            size: 20,
                          ),
                        ),
                        tooltip: isFav
                            ? 'Hapus dari favorit'
                            : 'Simpan ke favorit',
                        onPressed: () {
                          controller.toggleFavorite(hero.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isFav
                                    ? '${hero.name} dihapus dari favorit.'
                                    : '⭐ ${hero.name} ditambahkan ke daftar pahlawan favorit!',
                              ),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Latar Belakang Gradien Patriotik Merah Marun & Emas
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFF8B0000),
                              Color(0xFF5A0005),
                              Color(0xFF1E293B),
                            ],
                            stops: [0.0, 0.6, 1.0],
                          ),
                        ),
                      ),

                      // Hiasan Aksen Garis Emas & Garuda Halus
                      Positioned(
                        top: 20,
                        right: -30,
                        child: Icon(
                          Icons.shield_outlined,
                          size: 190,
                          color: Colors.white.withValues(alpha: 0.04),
                        ),
                      ),

                      // ELEMEN BOX PEMBINGKAI FOTO PAHLAWAN (Foto diam di dalam box, jelas & tidak ngezoom)
                      SafeArea(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 10),
                              // Elemen Box Potret
                              Container(
                                width: 165,
                                height: 215,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade900,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: AppTheme.accentGold,
                                    width: 3.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.5,
                                      ),
                                      blurRadius: 22,
                                      offset: const Offset(0, 10),
                                    ),
                                    BoxShadow(
                                      color: AppTheme.accentGold.withValues(
                                        alpha: 0.35,
                                      ),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Hero(
                                        tag: 'hero_photo_${hero.id}',
                                        child: Image.asset(
                                          hero.photoPath,
                                          fit: BoxFit.contain, // Foto UTUH dan tidak ngezoom
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                                    color: Colors.grey.shade800,
                                                    child: const Icon(
                                                      Icons.person,
                                                      size: 70,
                                                      color: Colors.white54,
                                                    ),
                                                  ),
                                        ),
                                      ),
                                      // Elemen Bar Penutup Bawah (Badge Arsip Resmi)
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          color: Colors.black.withValues(
                                            alpha: 0.8,
                                          ),
                                          child: const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.verified_rounded,
                                                color: AppTheme.accentGold,
                                                size: 11,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'POTRET RESMI',
                                                style: TextStyle(
                                                  color: AppTheme.accentGold,
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1.1,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Badge Era Perjuangan
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryRed,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  hero.struggleEra,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Nama Pahlawan
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: Text(
                                  hero.name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black,
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),

                              // Gelar Pahlawan
                              Text(
                                hero.knownAs,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppTheme.accentGold,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Overlapping Smooth Rounded Body
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -20),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.backgroundLight,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 12,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 100),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Inspiring Golden Quote Card (Always present for inspiration)
                            const SizedBox(height: 8),
                            _buildGoldenQuoteCard(context, hero),
                            const SizedBox(height: 18),

                            // 2. Dynamic Floating Metric Capsules (Quick Stats)
                            _buildQuickMetricsCapsules(hero),
                            const SizedBox(height: 20),

                            // 3. Interactive Dynamic Tab Selector
                            _buildDynamicTabSelector(),
                            const SizedBox(height: 18),

                            // 4. Tab Content View (Smoothly Animated)
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 320),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, anim) {
                                return FadeTransition(
                                  opacity: anim,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.04),
                                      end: Offset.zero,
                                    ).animate(anim),
                                    child: child,
                                  ),
                                );
                              },
                              child: _buildActiveTabContent(hero),
                            ),
                            const SizedBox(height: 20),

                            // 5. SK Penetapan & Persemayaman Card
                            _buildDecreeAndRestingPlaceCard(hero),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Bottom Floating Action Dock
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: _buildFloatingActionDock(context, hero, isFav, controller),
          ),
        ],
      ),
    );
  }

  /// Kapsul Metrik Dinamis (Quick Data Badges)
  Widget _buildQuickMetricsCapsules(HeroModel hero) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = constraints.maxWidth >= 700 ? 4 : 2;
        final itemWidth =
            (constraints.maxWidth - (columnCount - 1) * 10) / columnCount;

        return Wrap(
          alignment: WrapAlignment.spaceEvenly,
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: itemWidth,
              child: _buildPillBadge(
                icon: Icons.access_time_filled_rounded,
                label: 'Masa Hidup',
                value: hero.lifeTimeYears,
                color: AppTheme.primaryRed,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildPillBadge(
                icon: Icons.hourglass_bottom_rounded,
                label: 'Usia Wafat',
                value: '${hero.ageAtDeath} Tahun',
                color: AppTheme.warmAmber,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildPillBadge(
                icon: Icons.explore_rounded,
                label: 'Wilayah',
                value: hero.regionGroup,
                color: Colors.teal.shade700,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildPillBadge(
                icon: Icons.pin_drop_rounded,
                label: 'Asal',
                value: hero.originCity,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPillBadge({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textMuted,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.deepNavy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Segmented Tab Selector Interaktif & Dinamis
  Widget _buildDynamicTabSelector() {
    final tabs = [
      {'title': 'Linimasa & Data', 'icon': Icons.timeline_rounded},
      {'title': 'Biografi Lengkap', 'icon': Icons.menu_book_rounded},
      {'title': 'Jasa Perjuangan', 'icon': Icons.military_tech_rounded},
    ];

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.grey.shade200.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _activeTabIndex == index;
          final tab = tabs[index];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _activeTabIndex = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      tab['icon'] as IconData,
                      size: 16,
                      color: isSelected
                          ? AppTheme.primaryRed
                          : AppTheme.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        tab['title'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected
                              ? AppTheme.primaryRed
                              : AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Konten Tab yang Dipilih
  Widget _buildActiveTabContent(HeroModel hero) {
    switch (_activeTabIndex) {
      case 0:
        return KeyedSubtree(
          key: const ValueKey<int>(0),
          child: _buildTimelineAndLifetimeView(hero),
        );
      case 1:
        return KeyedSubtree(
          key: const ValueKey<int>(1),
          child: _buildFullBiographyView(hero),
        );
      case 2:
      default:
        return KeyedSubtree(
          key: const ValueKey<int>(2),
          child: _buildContributionsView(hero),
        );
    }
  }

  /// TAB 1: Linimasa Visual & Biodata Terstruktur
  Widget _buildTimelineAndLifetimeView(HeroModel hero) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.history_edu_rounded,
                  color: AppTheme.primaryRed,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Linimasa Riwayat Hidup (Lifetime)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.deepNavy,
                    ),
                  ),
                  Text(
                    'Kelahiran, perjuangan hingga akhir hayat',
                    style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 28),

          // Visual Stepper Linimasa
          _buildTimelineStep(
            icon: Icons.child_care_rounded,
            color: Colors.green.shade600,
            title: 'Kelahiran',
            subtitle: hero.birthDate,
            detail: 'Dilahirkan di ${hero.birthPlace}',
            isFirst: true,
          ),
          _buildTimelineStep(
            icon: Icons.flag_rounded,
            color: AppTheme.primaryRed,
            title: 'Daerah Asal & Perjuangan',
            subtitle: '${hero.fullOrigin} (${hero.regionGroup})',
            detail: 'Bergerak pada era ${hero.struggleEra}',
          ),
          _buildTimelineStep(
            icon: Icons.nightlight_round,
            color: Colors.indigo.shade600,
            title: 'Wafat & Tutup Usia',
            subtitle: '${hero.deathDate} (${hero.ageAtDeath} Tahun)',
            detail: 'Wafat di ${hero.deathPlace}',
          ),
          _buildTimelineStep(
            icon: Icons.location_city_rounded,
            color: AppTheme.warmAmber,
            title: 'Tempat Persemayaman Terakhir',
            subtitle: 'Makam Kehormatan',
            detail: hero.burialPlace,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String detail,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator line + icon dot
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey.shade300,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.deepNavy,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    detail,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.textMuted,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// TAB 2: Kisah Biografi Mendalam
  Widget _buildFullBiographyView(HeroModel hero) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ringkasan Cepat Biografi (Highlight Card)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.shade50,
                  Colors.orange.shade50.withValues(alpha: 0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.warmAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: AppTheme.warmAmber,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ringkasan Singkat',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.warmAmber,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hero.shortBio,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.brown.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Rekam Jejak & Catatan Sejarah',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.deepNavy,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            hero.fullBio,
            style: const TextStyle(
              fontSize: 14,
              height: 1.7,
              color: Color(0xFF334155),
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  /// TAB 3: Jasa & Kontribusi Besar Bagi Bangsa
  Widget _buildContributionsView(HeroModel hero) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.stars_rounded,
                  color: Colors.blue.shade800,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Peran & Jasa Kunci bagi Bangsa',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.deepNavy,
                    ),
                  ),
                  Text(
                    'Tonggak penting perjuangan kemerdekaan',
                    style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...hero.keyContributions.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final text = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRed.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$idx',
                      style: const TextStyle(
                        color: AppTheme.primaryRed,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.45,
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Kutipan Emas Patriotik
  Widget _buildGoldenQuoteCard(BuildContext context, HeroModel hero) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFBA1A1A), Color(0xFF7F000A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryRed.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(
                Icons.format_quote_rounded,
                color: AppTheme.accentGold,
                size: 38,
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.copy_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  tooltip: 'Salin Kutipan Inspiratif',
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(
                        text: '"${hero.famousQuote}" — ${hero.name}',
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          '✨ Kutipan berhasil disalin ke clipboard!',
                        ),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '"${hero.famousQuote}"',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15.5,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '— ${hero.name} • ${hero.quoteContext}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Kartu Dasar SK Penetapan & Persemayaman
  Widget _buildDecreeAndRestingPlaceCard(HeroModel hero) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.verified_rounded, size: 18, color: Colors.green),
              SizedBox(width: 8),
              Text(
                'Legalitas & Penghormatan Negara',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.deepNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '• ',
                style: TextStyle(
                  color: AppTheme.primaryRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Text(
                  'Dasar Penetapan Gelar: ${hero.decreeNumber}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '• ',
                style: TextStyle(
                  color: AppTheme.primaryRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Text(
                  'Lokasi Persemayaman: ${hero.burialPlace}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Floating Action Dock Modern di Bawah Layar
  Widget _buildFloatingActionDock(
    BuildContext context,
    HeroModel hero,
    bool isFav,
    PahlawanController controller,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Tombol Beri Hormat (Salute Interaktif)
          Material(
            color: AppTheme.warmAmber.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                setState(() {
                  _saluteCount++;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '🫡 Anda memberikan hormat kepada ${hero.name}! ($_saluteCount kali)',
                    ),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🫡', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      _saluteCount == 0
                          ? 'Beri Hormat'
                          : '$_saluteCount Hormat',
                      style: const TextStyle(
                        color: AppTheme.warmAmber,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Tombol Salin Kutipan
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(
                    text:
                        '${hero.name} (${hero.knownAs})\nAsal: ${hero.fullOrigin}\nMasa Hidup: ${hero.lifeTimeYears}\n\n"${hero.famousQuote}"',
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      '📋 Ringkasan pahlawan berhasil disalin! Siap dibagikan.',
                    ),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.share_rounded, size: 16),
              label: const Text(
                'Bagikan Info',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
