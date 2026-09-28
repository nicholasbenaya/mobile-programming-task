import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/pahlawan_controller.dart';
import '../../models/hero_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/hero_image.dart';
import '../widgets/stat_card.dart';
import 'hero_admin_screen.dart';
import 'hero_detail_screen.dart';
import 'hero_favorites_screen.dart';
import '../widgets/favorite_gallery_card.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final TextEditingController _searchController;
  PahlawanController? _controller;

  @override
  void initState() {
    super.initState();
    final query = context.read<PahlawanController>().searchQuery;
    _searchController = TextEditingController(text: query);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newController = context.read<PahlawanController>();
    if (_controller != newController) {
      _controller?.removeListener(_onControllerQueryChanged);
      _controller = newController;
      _controller?.addListener(_onControllerQueryChanged);
      _onControllerQueryChanged();
    }
  }

  void _onControllerQueryChanged() {
    final query = _controller?.searchQuery ?? '';
    if (_searchController.text != query) {
      _searchController.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerQueryChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchSubmit(String query, PahlawanController controller) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      widget.onNavigateTab?.call(1);
      return;
    }
    // Netralkan filter wilayah & era agar pencarian global dari beranda menemukan tokoh
    controller.setSelectedRegion('Semua');
    controller.setSelectedEra('Semua');
    controller.setSearchQuery(trimmed);
    widget.onNavigateTab?.call(1);
  }

  void _selectRegionAndNavigate(String region, PahlawanController controller) {
    controller.setSearchQuery('');
    controller.setSelectedEra('Semua');
    controller.setSelectedRegion(region);
    widget.onNavigateTab?.call(1);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PahlawanController>();
    final featured = controller.featuredHero;

    // Pahlawan dengan kutipan otentik untuk ditampilkan di kartu kutipan inspiratif
    final quoteHeroes = controller.allHeroes
        .where(
          (h) =>
              h.famousQuote.isNotEmpty &&
              h.famousQuote != 'Kutipan khusus belum tersedia dalam dataset.',
        )
        .toList();
    final quoteHero = quoteHeroes.isNotEmpty
        ? quoteHeroes[DateTime.now().day % quoteHeroes.length]
        : featured;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                color: AppTheme.accentGold,
                size: 19,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pahlawan Nasional',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.deepNavy,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Pusaka Bangsa & Arsip Sejarah',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Pahlawan Favorit',
            icon: Badge(
              label: Text('${controller.totalFavorites}'),
              isLabelVisible: controller.totalFavorites > 0,
              backgroundColor: AppTheme.crimsonAccent,
              child: const Icon(Icons.bookmark_outline_rounded),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HeroFavoritesScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Kelola Data Pahlawan',
            icon: const Icon(Icons.admin_panel_settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HeroAdminScreen()),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () async {
          controller.resetFilters();
          await controller.loadData(showLoading: false);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HEROIC WELCOME BANNER (Gaya Archival / Museum Prestisius)
              _buildHeroWelcomeBanner(context, controller),
              const SizedBox(height: 20),

              // 2. RINGKASAN DATA STATISTIK
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ringkasan Koleksi & Arsip',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.deepNavy,
                    ),
                  ),
                  Text(
                    'Total ${controller.totalHeroes} Tokoh',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildStatsGrid(context, controller),
              const SizedBox(height: 22),

              // 2.1 GALERI FAVORIT ANDA (Preview Galeri jika ada tokoh tersimpan)
              if (controller.favoriteHeroes.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.military_tech_rounded,
                          color: AppTheme.accentGold,
                          size: 20,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Galeri Favorit Anda',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.deepNavy,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: AppTheme.primary,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const HeroFavoritesScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Buka Galeri (${controller.totalFavorites}) →',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildFavoritesHorizontalRibbon(context, controller),
                const SizedBox(height: 22),
              ],

              // 3. TOKOH PILIHAN HARI INI
              if (featured != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pahlawan Pilihan Hari Ini',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.deepNavy,
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: AppTheme.primary,
                      ),
                      onPressed: () => widget.onNavigateTab?.call(1),
                      child: const Text(
                        'Lihat Semua →',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildFeaturedCard(context, featured, controller),
                const SizedBox(height: 22),
              ],

              // 4. WASIAT & KUTIPAN BERSEJARAH (Mutiara Kata Perjuangan)
              if (quoteHero != null) ...[
                _buildQuoteOfTheDayCard(context, quoteHero),
                const SizedBox(height: 22),
              ],

              // 5. JELAJAHI BERDASARKAN WILAYAH
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Jelajahi Berdasarkan Wilayah',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.deepNavy,
                    ),
                  ),
                  Text(
                    'Nusantara',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentGold.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildRegionExplorer(context, controller),
              const SizedBox(height: 24),

              // 6. MENU JELAJAHI FITUR APLIKASI
              const Text(
                'Jelajahi Modul Pembelajaran',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.deepNavy,
                ),
              ),
              const SizedBox(height: 10),
              _buildFeatureShortcuts(context, controller),
            ],
          ),
        ),
      ),
    );
  }

  /// 1. Heroic Welcome Banner dengan Search Bar Terintegrasi
  Widget _buildHeroWelcomeBanner(BuildContext context, PahlawanController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F4C5C), Color(0xFF072B35)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F4C5C).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: AppTheme.accentGold.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge Mahkota / Nusantara
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.accentGold.withValues(alpha: 0.6),
                    width: 0.8,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 13,
                      color: AppTheme.accentGold,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'ARSIP SEJARAH INDONESIA',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentGold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 18,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Judul Utama Banner
          const Text(
            'Kenali Jejak Juang & Wasiat Pahlawan Bangsa',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.4,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),

          // Subjudul
          Text(
            'Telusuri 183 tokoh pelopor kemerdekaan dari seluruh penjuru Nusantara, lengkap dengan biografi, potret asli, dan wasiat bersejarah.',
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),

          // Search Box Interaktif di dalam Banner
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onChanged: (val) {
              controller.setSearchQuery(val.trim());
              setState(() {});
            },
            onSubmitted: (val) => _onSearchSubmit(val, controller),
            style: const TextStyle(color: AppTheme.deepNavy, fontSize: 13.5),
            decoration: InputDecoration(
              hintText: 'Cari pahlawan, kota asal, atau peristiwa...',
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                      tooltip: 'Hapus Pencarian',
                      onPressed: () {
                        _searchController.clear();
                        controller.setSearchQuery('');
                        setState(() {});
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded, color: AppTheme.primary),
                    tooltip: 'Cari',
                    onPressed: () => _onSearchSubmit(_searchController.text, controller),
                  ),
                ],
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Grid Statistik 4 Kartu Prestisius
  Widget _buildStatsGrid(BuildContext context, PahlawanController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 500;
        return GridView.count(
          crossAxisCount: isWide ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: isWide ? 2.0 : 1.95,
          children: [
            StatCard(
              title: 'Total Pahlawan',
              value: '${controller.totalHeroes}',
              icon: Icons.groups_rounded,
              color: AppTheme.primary,
              onTap: () => widget.onNavigateTab?.call(1),
            ),
            StatCard(
              title: 'Wilayah Asal',
              value: '${controller.totalRegions} Wilayah',
              icon: Icons.map_rounded,
              color: AppTheme.accentGold,
              onTap: () => widget.onNavigateTab?.call(1),
            ),
            StatCard(
              title: 'Foto Galeri',
              value: '${controller.totalPhotos} Potret',
              icon: Icons.photo_library_rounded,
              color: const Color(0xFF0284C7), // Samudra Biru
              onTap: () => widget.onNavigateTab?.call(2),
            ),
            StatCard(
              title: 'Favorit Anda',
              value: '${controller.totalFavorites} Tersimpan',
              icon: Icons.bookmark_rounded,
              color: AppTheme.crimsonAccent,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HeroFavoritesScreen()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  /// 2b. Pita Galeri Pahlawan Favorit (Preview Horizontal di Dashboard)
  Widget _buildFavoritesHorizontalRibbon(
    BuildContext context,
    PahlawanController controller,
  ) {
    final favorites = controller.favoriteHeroes;
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: favorites.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final hero = favorites[index];
          return SizedBox(
            width: 155,
            child: FavoriteGalleryCard(
              hero: hero,
              showQuote: false,
              onRemove: () {
                controller.toggleFavorite(hero.id);
              },
            ),
          );
        },
      ),
    );
  }

  /// 3. Kartu Spotlight Pahlawan Hari Ini
  Widget _buildFeaturedCard(
    BuildContext context,
    HeroModel featured,
    PahlawanController controller,
  ) {
    final isFav = controller.isFavorite(featured.id);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.07),
            blurRadius: 14,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Foto Pahlawan Spotlight
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 88,
                            height: 108,
                            color: AppTheme.primary.withValues(alpha: 0.08),
                            child: heroImage(
                              featured.photoPath,
                              width: 88,
                              height: 108,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: AppTheme.accentGold,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.star_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),

                    // Detail Singkat
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tag Era
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              featured.struggleEra.isNotEmpty
                                  ? featured.struggleEra
                                  : 'Pahlawan Kemerdekaan',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Nama Pahlawan
                          Text(
                            featured.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.deepNavy,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 2),

                          // Gelar / Dikenal Sebagai
                          if (featured.knownAs.isNotEmpty)
                            Text(
                              featured.knownAs,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.warmAmber,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                          const SizedBox(height: 6),

                          // Asal Daerah & Masa Hidup
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 13,
                                color: AppTheme.textMuted,
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  '${featured.regionGroup} • ${featured.fullOrigin}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppTheme.textMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                Icons.history_rounded,
                                size: 13,
                                color: AppTheme.textMuted,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                featured.lifeTimeYears,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Tombol Favorit
                    IconButton(
                      icon: Icon(
                        isFav
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: isFav
                            ? AppTheme.crimsonAccent
                            : Colors.grey.shade400,
                      ),
                      tooltip: isFav ? 'Hapus dari Favorit' : 'Tambah ke Favorit',
                      onPressed: () => controller.toggleFavorite(featured.id),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Ringkasan Biografi
                Text(
                  featured.shortBio,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.textMuted,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 12),

                // Tombol Buka Detail
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (featured.famousQuote.isNotEmpty &&
                        featured.famousQuote !=
                            'Kutipan khusus belum tersedia dalam dataset.')
                      Expanded(
                        child: Text(
                          '"${featured.famousQuote}"',
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    else
                      const Spacer(),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Buka Profil',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 13, color: Colors.white),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 4. Kartu Wasiat & Kutipan Bersejarah Pilihan
  Widget _buildQuoteOfTheDayCard(BuildContext context, HeroModel hero) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.lightGold,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.accentGold.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppTheme.accentGold,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.format_quote_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'MUTIARA KATA & WASIAT PERJUANGAN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.warmAmber,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).push(HeroDetailScreen.route(hero)),
                child: const Text(
                  'Lihat Tokoh →',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '"${hero.famousQuote}"',
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              color: AppTheme.deepNavy,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '— ${hero.name}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              if (hero.quoteContext.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  '(${hero.quoteContext})',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// 5. Jelajahi Berdasarkan Wilayah Kepulauan Nusantara
  Widget _buildRegionExplorer(BuildContext context, PahlawanController controller) {
    final regions = [
      ('Jawa', Icons.landscape_rounded, const Color(0xFF0F4C5C)),
      ('Sumatera', Icons.forest_rounded, const Color(0xFF15803D)),
      ('Sulawesi', Icons.waves_rounded, const Color(0xFF0284C7)),
      ('Maluku', Icons.sailing_rounded, const Color(0xFF7C3AED)),
      ('Bali & Nusa', Icons.temple_hindu_rounded, const Color(0xFFD97706)),
      ('Papua', Icons.terrain_rounded, const Color(0xFFBE123C)),
    ];

    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: regions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final (name, icon, color) = regions[index];
          final count = controller.allHeroes
              .where((h) => h.regionGroup == name)
              .length;

          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _selectRegionAndNavigate(name, controller),
              child: Container(
                width: 124,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Icon(icon, color: color, size: 18),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.deepNavy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Pahlawan',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 6. Modul Pintas Fitur
  Widget _buildFeatureShortcuts(BuildContext context, PahlawanController controller) {
    return Row(
      children: [
        Expanded(
          child: _buildShortcutButton(
            context,
            title: 'Daftar Pahlawan',
            subtitle: '${controller.totalHeroes} Biodata',
            icon: Icons.list_alt_rounded,
            color: AppTheme.primary,
            onTap: () => widget.onNavigateTab?.call(1),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildShortcutButton(
            context,
            title: 'Galeri Foto',
            subtitle: '${controller.totalPhotos} Potret',
            icon: Icons.grid_view_rounded,
            color: AppTheme.accentGold,
            onTap: () => widget.onNavigateTab?.call(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildShortcutButton(
            context,
            title: 'Kuis Sejarah',
            subtitle: 'Uji Wawasan',
            icon: Icons.quiz_rounded,
            color: const Color(0xFF0284C7),
            onTap: () => widget.onNavigateTab?.call(3),
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.deepNavy,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
