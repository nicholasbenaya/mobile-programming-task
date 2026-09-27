import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/pahlawan_controller.dart';
import '../../models/hero_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/hero_image.dart';
import '../widgets/favorite_gallery_card.dart';
import 'hero_detail_screen.dart';

enum FavoriteSortOption {
  nameAsc,
  nameDesc,
  region,
}

class HeroFavoritesScreen extends StatefulWidget {
  const HeroFavoritesScreen({super.key});

  @override
  State<HeroFavoritesScreen> createState() => _HeroFavoritesScreenState();
}

class _HeroFavoritesScreenState extends State<HeroFavoritesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedRegion = 'Semua';
  bool _isGalleryMode = true; // Default tampilan galeri visual
  FavoriteSortOption _sortOption = FavoriteSortOption.nameAsc;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmClearAll(
    BuildContext context,
    PahlawanController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.bookmark_remove_rounded, color: AppTheme.primaryRed),
            SizedBox(width: 8),
            Text('Kosongkan Galeri Favorit?'),
          ],
        ),
        content: const Text(
          'Semua tokoh pahlawan yang Anda tandai akan dihapus dari koleksi galeri favorit.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final ids = List<String>.from(controller.favoriteIds);
      for (final id in ids) {
        await controller.toggleFavorite(id);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seluruh koleksi favorit berhasil dikosongkan.'),
          ),
        );
      }
    }
  }

  void _removeFavoriteWithUndo(
    BuildContext context,
    PahlawanController controller,
    HeroModel hero,
  ) {
    controller.toggleFavorite(hero.id);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${hero.name} dihapus dari galeri favorit.'),
        action: SnackBarAction(
          label: 'Urungkan',
          textColor: AppTheme.accentGold,
          onPressed: () {
            controller.toggleFavorite(hero.id);
          },
        ),
      ),
    );
  }

  List<HeroModel> _getFilteredAndSortedFavorites(List<HeroModel> favorites) {
    var result = List<HeroModel>.from(favorites);

    // Filter pencarian
    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((h) {
        return h.name.toLowerCase().contains(q) ||
            h.knownAs.toLowerCase().contains(q) ||
            h.originCity.toLowerCase().contains(q) ||
            h.originProvince.toLowerCase().contains(q) ||
            h.regionGroup.toLowerCase().contains(q) ||
            h.famousQuote.toLowerCase().contains(q);
      }).toList();
    }

    // Filter wilayah
    if (_selectedRegion != 'Semua') {
      result = result.where((h) => h.regionGroup == _selectedRegion).toList();
    }

    // Pengurutan
    switch (_sortOption) {
      case FavoriteSortOption.nameAsc:
        result.sort((a, b) => a.name.compareTo(b.name));
        break;
      case FavoriteSortOption.nameDesc:
        result.sort((a, b) => b.name.compareTo(a.name));
        break;
      case FavoriteSortOption.region:
        result.sort((a, b) {
          final regComp = a.regionGroup.compareTo(b.regionGroup);
          if (regComp != 0) return regComp;
          return a.name.compareTo(b.name);
        });
        break;
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PahlawanController>();
    final allFavorites = controller.favoriteHeroes;
    final filtered = _getFilteredAndSortedFavorites(allFavorites);

    // Ambil daftar wilayah unik dari tokoh favorit yang ada
    final availableRegions = ['Semua', ...allFavorites.map((h) => h.regionGroup).toSet()];

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pahlawan Favorit',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.deepNavy,
              ),
            ),
            Text(
              'Galeri Koleksi Pribadi Tokoh Teladan',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          if (allFavorites.isNotEmpty) ...[
            // Toggle Tampilan: Galeri Grid vs Daftar List
            IconButton(
              tooltip: _isGalleryMode ? 'Ubah ke Mode Daftar' : 'Ubah ke Mode Galeri',
              icon: Icon(
                _isGalleryMode
                    ? Icons.view_agenda_rounded
                    : Icons.grid_view_rounded,
                color: AppTheme.primary,
              ),
              onPressed: () {
                setState(() => _isGalleryMode = !_isGalleryMode);
              },
            ),

            // Menu Urutkan
            PopupMenuButton<FavoriteSortOption>(
              tooltip: 'Urutkan Favorit',
              icon: const Icon(Icons.sort_rounded, color: AppTheme.primary),
              initialValue: _sortOption,
              onSelected: (opt) => setState(() => _sortOption = opt),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: FavoriteSortOption.nameAsc,
                  child: Row(
                    children: [
                      Icon(Icons.sort_by_alpha_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Nama (A – Z)'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: FavoriteSortOption.nameDesc,
                  child: Row(
                    children: [
                      Icon(Icons.text_rotate_vertical_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Nama (Z – A)'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: FavoriteSortOption.region,
                  child: Row(
                    children: [
                      Icon(Icons.map_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Gugus Wilayah'),
                    ],
                  ),
                ),
              ],
            ),

            // Tombol Hapus Semua
            IconButton(
              tooltip: 'Hapus Semua Favorit',
              icon: const Icon(Icons.delete_sweep_outlined, color: AppTheme.textMuted),
              onPressed: () => _confirmClearAll(context, controller),
            ),
          ],
        ],
      ),
      body: allFavorites.isEmpty
          ? _buildEmptyState(context, controller)
          : Column(
              children: [
                // 1. Banner Galeri Favorit
                _buildGalleryHeaderBanner(allFavorites.length, filtered.length),

                // 2. Search & Filter Bar
                _buildSearchAndFilters(allFavorites, availableRegions),

                // 3. Konten Utama: Galeri Grid atau Daftar List
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmptyFilterState()
                      : _isGalleryMode
                          ? _buildGalleryGridView(context, controller, filtered)
                          : _buildListView(context, controller, filtered),
                ),
              ],
            ),
    );
  }

  /// Banner Pembuka Koleksi Pusaka Favorit
  Widget _buildGalleryHeaderBanner(int total, int showing) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary,
            AppTheme.deepNavy,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.accentGold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.accentGold.withValues(alpha: 0.5),
              ),
            ),
            child: const Icon(
              Icons.military_tech_rounded,
              color: AppTheme.accentGold,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Galeri Pusaka Favorit Anda',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Menampilkan $showing dari $total pahlawan teladan pilihan',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.accentGold,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star_rounded,
                  size: 14,
                  color: AppTheme.deepNavy,
                ),
                const SizedBox(width: 3),
                Text(
                  '$total',
                  style: const TextStyle(
                    color: AppTheme.deepNavy,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Search Bar dan Chip Filter Wilayah
  Widget _buildSearchAndFilters(
    List<HeroModel> allFavorites,
    List<String> availableRegions,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Cari nama, kota asal, atau kutipan favorit...',
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 13,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),

          // Horizontal Filter Chips Wilayah (Jika ada lebih dari 1 wilayah)
          if (availableRegions.length > 2) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: availableRegions.map((region) {
                  final isSelected = _selectedRegion == region;
                  final count = region == 'Semua'
                      ? allFavorites.length
                      : allFavorites.where((h) => h.regionGroup == region).length;

                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text('$region ($count)'),
                      labelStyle: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : AppTheme.deepNavy,
                      ),
                      backgroundColor: Colors.white,
                      selectedColor: AppTheme.primary,
                      side: BorderSide(
                        color: isSelected
                            ? AppTheme.primary
                            : Colors.grey.shade300,
                        width: isSelected ? 1.5 : 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      onSelected: (_) {
                        setState(() => _selectedRegion = region);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Tampilan 1: Mode Galeri Grid (Mewah & Sinematik)
  Widget _buildGalleryGridView(
    BuildContext context,
    PahlawanController controller,
    List<HeroModel> heroes,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900
            ? 4
            : constraints.maxWidth > 600
                ? 3
                : 2;

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.66,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: heroes.length,
          itemBuilder: (context, index) {
            final hero = heroes[index];
            return FavoriteGalleryCard(
              hero: hero,
              onRemove: () => _removeFavoriteWithUndo(context, controller, hero),
            );
          },
        );
      },
    );
  }

  /// Tampilan 2: Mode Daftar List (Ringkas)
  Widget _buildListView(
    BuildContext context,
    PahlawanController controller,
    List<HeroModel> heroes,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: heroes.length,
      itemBuilder: (context, index) {
        final hero = heroes[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.accentGold.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.of(context).push(HeroDetailScreen.route(hero));
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Avatar Potret dengan border emas
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.accentGold,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          hero.photoPath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.person, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Detail Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  hero.regionGroup,
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  hero.lifeTimeYears,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: AppTheme.textMuted,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            hero.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.deepNavy,
                            ),
                          ),
                          if (hero.famousQuote.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              '"${hero.famousQuote}"',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Tombol Hapus Favorit
                    IconButton(
                      tooltip: 'Hapus dari Favorit',
                      icon: const Icon(
                        Icons.star_rounded,
                        color: AppTheme.accentGold,
                        size: 24,
                      ),
                      onPressed: () => _removeFavoriteWithUndo(
                        context,
                        controller,
                        hero,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Tampilan Ketika Filter / Pencarian Tidak Menemukan Hasil
  Widget _buildEmptyFilterState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 52,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 14),
            Text(
              'Tidak ditemukan favorit untuk "$_searchQuery"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.deepNavy,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Coba gunakan kata kunci lain atau pilih filter wilayah "Semua".',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedRegion = 'Semua';
                });
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Reset Pencarian'),
            ),
          ],
        ),
      ),
    );
  }

  /// Empty State: Ketika Belum Ada Pahlawan Favorit Sama Sekali
  Widget _buildEmptyState(
    BuildContext context,
    PahlawanController controller,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Medallion Ornamen Bintang Emas & Zamrud
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.accentGold.withValues(alpha: 0.25),
                    AppTheme.primary.withValues(alpha: 0.08),
                  ],
                ),
                border: Border.all(
                  color: AppTheme.accentGold.withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentGold.withValues(alpha: 0.15),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 48,
                  color: AppTheme.accentGold,
                ),
              ),
            ),
            const SizedBox(height: 22),

            // Judul Penting untuk Pengujian dan User
            const Text(
              'Belum Ada Pahlawan Favorit',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: AppTheme.deepNavy,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Koleksi galeri pahlawan pilihan Anda masih kosong. Tandai pahlawan yang paling menginspirasi Anda dengan menekan ikon bintang pada kartu pahlawan untuk membangun galeri tokoh teladan bangsa.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 26),

            // Tombol Aksi Utama: Jelajahi Pahlawan
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: const Text(
                'Jelajahi Galeri Pahlawan',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            // Saran Pahlawan Terkenal Cepat
            if (controller.allHeroes.isNotEmpty) ...[
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 1,
                    width: 36,
                    color: Colors.grey.shade300,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'Rekomendasi Tokoh Inspiratif',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                  Container(
                    height: 1,
                    width: 36,
                    color: Colors.grey.shade300,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: controller.allHeroes.take(4).map((h) {
                  return ActionChip(
                    avatar: CircleAvatar(
                      backgroundColor: Colors.grey.shade200,
                      child: ClipOval(
                        child: heroImage(
                          h.photoPath,
                          fit: BoxFit.cover,
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ),
                    label: Text(
                      h.name,
                      style: const TextStyle(fontSize: 11.5),
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: AppTheme.accentGold.withValues(alpha: 0.4),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(HeroDetailScreen.route(h));
                    },
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
