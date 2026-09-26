import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controllers/pahlawan_controller.dart';
import '../../models/hero_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/hero_image.dart';
import 'hero_detail_screen.dart';
import 'hero_editor_screen.dart';

enum AdminSortMode {
  nameAsc('Nama (A – Z)', Icons.sort_by_alpha_rounded),
  nameDesc('Nama (Z – A)', Icons.sort_by_alpha_rounded),
  birthYearAsc('Tahun Lahir (Tertua)', Icons.calendar_today_rounded),
  birthYearDesc('Tahun Lahir (Termuda)', Icons.calendar_month_rounded),
  idAsc('ID Sistem (A – Z)', Icons.tag_rounded);

  final String label;
  final IconData icon;
  const AdminSortMode(this.label, this.icon);
}

enum AdminStatusFilter {
  all('Semua'),
  hasQuote('Ada Kutipan'),
  noQuote('Belum Ada Kutipan'),
  noPhoto('Tanpa Foto');

  final String label;
  const AdminStatusFilter(this.label);
}

class HeroAdminScreen extends StatefulWidget {
  const HeroAdminScreen({super.key});

  @override
  State<HeroAdminScreen> createState() => _HeroAdminScreenState();
}

class _HeroAdminScreenState extends State<HeroAdminScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedRegion = 'Semua';
  String _selectedEra = 'Semua';
  AdminStatusFilter _statusFilter = AdminStatusFilter.all;
  AdminSortMode _sortMode = AdminSortMode.nameAsc;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _hasCustomQuote(HeroModel hero) {
    final q = hero.famousQuote.trim();
    return q.isNotEmpty && q != 'Kutipan khusus belum tersedia dalam dataset.';
  }

  bool _hasPhoto(HeroModel hero) {
    final p = hero.photoPath.trim();
    return p.isNotEmpty &&
        p != 'assets/images/' &&
        p != 'assets/images/placeholder.png';
  }

  int _extractYear(String dateStr) {
    final match = RegExp(r'\b\d{4}\b').firstMatch(dateStr);
    return match != null ? int.tryParse(match.group(0)!) ?? 0 : 0;
  }

  bool get _isFilterActive =>
      _searchQuery.isNotEmpty ||
      _selectedRegion != 'Semua' ||
      _selectedEra != 'Semua' ||
      _statusFilter != AdminStatusFilter.all ||
      _sortMode != AdminSortMode.nameAsc;

  void _resetAllFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedRegion = 'Semua';
      _selectedEra = 'Semua';
      _statusFilter = AdminStatusFilter.all;
      _sortMode = AdminSortMode.nameAsc;
    });
  }

  List<HeroModel> _filterAndSortHeroes(List<HeroModel> allHeroes) {
    final query = _searchQuery.trim().toLowerCase();

    final filtered = allHeroes.where((hero) {
      if (query.isNotEmpty) {
        final match = hero.name.toLowerCase().contains(query) ||
            hero.knownAs.toLowerCase().contains(query) ||
            hero.originCity.toLowerCase().contains(query) ||
            hero.originProvince.toLowerCase().contains(query) ||
            hero.regionGroup.toLowerCase().contains(query) ||
            hero.struggleEra.toLowerCase().contains(query) ||
            hero.decreeNumber.toLowerCase().contains(query) ||
            hero.id.toLowerCase().contains(query);
        if (!match) return false;
      }

      if (_selectedRegion != 'Semua' && hero.regionGroup != _selectedRegion) {
        return false;
      }

      if (_selectedEra != 'Semua' && hero.struggleEra != _selectedEra) {
        return false;
      }

      switch (_statusFilter) {
        case AdminStatusFilter.all:
          break;
        case AdminStatusFilter.hasQuote:
          if (!_hasCustomQuote(hero)) return false;
          break;
        case AdminStatusFilter.noQuote:
          if (_hasCustomQuote(hero)) return false;
          break;
        case AdminStatusFilter.noPhoto:
          if (_hasPhoto(hero)) return false;
          break;
      }

      return true;
    }).toList();

    filtered.sort((a, b) {
      switch (_sortMode) {
        case AdminSortMode.nameAsc:
          return a.name.compareTo(b.name);
        case AdminSortMode.nameDesc:
          return b.name.compareTo(a.name);
        case AdminSortMode.birthYearAsc:
          return _extractYear(a.birthDate).compareTo(_extractYear(b.birthDate));
        case AdminSortMode.birthYearDesc:
          return _extractYear(b.birthDate).compareTo(_extractYear(a.birthDate));
        case AdminSortMode.idAsc:
          return a.id.compareTo(b.id);
      }
    });

    return filtered;
  }

  Future<void> _create(BuildContext context) async {
    final values = await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute(builder: (_) => const HeroEditorScreen()),
    );
    if (values == null || !context.mounted) return;
    try {
      await context.read<PahlawanController>().createHero(values);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pahlawan "${values['name'] ?? 'Baru'}" berhasil ditambahkan.',
            ),
            backgroundColor: Colors.green.shade800,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambahkan pahlawan: $e'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    }
  }

  Future<void> _edit(BuildContext context, HeroModel hero) async {
    final values = await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute(builder: (_) => HeroEditorScreen(hero: hero)),
    );
    if (values == null || !context.mounted) return;
    try {
      await context.read<PahlawanController>().updateHero(hero.id, values);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data "${hero.name}" berhasil diperbarui.'),
            backgroundColor: Colors.green.shade800,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui data: $e'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    }
  }

  Future<void> _delete(BuildContext context, HeroModel hero) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.primaryRed),
            SizedBox(width: 8),
            Text('Hapus Pahlawan?'),
          ],
        ),
        content: Text(
          'Data "${hero.name}" akan dihapus secara permanen dari database.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryRed),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await context.read<PahlawanController>().deleteHero(hero.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${hero.name}" telah dihapus.'),
            backgroundColor: Colors.grey.shade800,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus data: $e'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    }
  }

  void _copyId(BuildContext context, HeroModel hero) {
    Clipboard.setData(ClipboardData(text: hero.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ID "${hero.id}" disalin ke papan klip.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _viewDetail(BuildContext context, HeroModel hero) {
    Navigator.of(context).push(HeroDetailScreen.route(hero));
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PahlawanController>();
    final allHeroes = controller.allHeroes;
    final filteredHeroes = _filterAndSortHeroes(allHeroes);

    // Dynamic regions based on data + defaults
    final regions = <String>['Semua'];
    for (final r in controller.availableRegions) {
      if (r != 'Semua' && !regions.contains(r)) regions.add(r);
    }
    for (final h in allHeroes) {
      if (h.regionGroup.isNotEmpty && !regions.contains(h.regionGroup)) {
        regions.add(h.regionGroup);
      }
    }

    // Dynamic eras based on data + defaults
    final eras = <String>['Semua'];
    for (final e in controller.availableEras) {
      if (e != 'Semua' && !eras.contains(e)) eras.add(e);
    }
    for (final h in allHeroes) {
      if (h.struggleEra.isNotEmpty && !eras.contains(h.struggleEra)) {
        eras.add(h.struggleEra);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Data Pahlawan'),
        actions: [
          if (_isFilterActive)
            IconButton(
              tooltip: 'Reset Pencarian & Filter',
              icon: const Icon(Icons.filter_alt_off_rounded, color: AppTheme.primaryRed),
              onPressed: _resetAllFilters,
            ),
          PopupMenuButton<AdminSortMode>(
            icon: const Icon(Icons.sort_rounded, color: AppTheme.deepNavy),
            tooltip: 'Urutkan Data',
            initialValue: _sortMode,
            onSelected: (mode) => setState(() => _sortMode = mode),
            itemBuilder: (_) => AdminSortMode.values
                .map(
                  (mode) => PopupMenuItem(
                    value: mode,
                    child: Row(
                      children: [
                        Icon(
                          mode.icon,
                          size: 18,
                          color: _sortMode == mode
                              ? AppTheme.primaryRed
                              : AppTheme.deepNavy,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          mode.label,
                          style: TextStyle(
                            fontWeight: _sortMode == mode
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: _sortMode == mode
                                ? AppTheme.primaryRed
                                : AppTheme.deepNavy,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context),
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Pahlawan'),
      ),
      body: Column(
        children: [
          // 1. Search Bar & Filter Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Cari nama, kota, gelar, SK, atau ID...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.5),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppTheme.primaryRed,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryRed,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),

          // 2. Filter Bar: Wilayah Chips
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: regions.length,
              itemBuilder: (context, index) {
                final region = regions[index];
                final isSelected = _selectedRegion == region;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(region),
                    selected: isSelected,
                    onSelected: (_) =>
                        setState(() => _selectedRegion = region),
                    selectedColor: AppTheme.primaryRed,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.primaryRed
                          : Colors.grey.shade300,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.deepNavy,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                    checkmarkColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 4),

          // 3. Status & Era Filters Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Status Filter Menu (Semua / Ada Kutipan / Belum Ada Kutipan / Tanpa Foto)
                PopupMenuButton<AdminStatusFilter>(
                  tooltip: 'Filter Status Data',
                  initialValue: _statusFilter,
                  onSelected: (status) => setState(() => _statusFilter = status),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _statusFilter != AdminStatusFilter.all
                          ? AppTheme.primaryRed.withValues(alpha: 0.1)
                          : Colors.white,
                      border: Border.all(
                        color: _statusFilter != AdminStatusFilter.all
                            ? AppTheme.primaryRed
                            : Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_outlined,
                          size: 14,
                          color: _statusFilter != AdminStatusFilter.all
                              ? AppTheme.primaryRed
                              : AppTheme.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _statusFilter.label,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: _statusFilter != AdminStatusFilter.all
                                ? AppTheme.primaryRed
                                : AppTheme.deepNavy,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 16,
                          color: _statusFilter != AdminStatusFilter.all
                              ? AppTheme.primaryRed
                              : AppTheme.textMuted,
                        ),
                      ],
                    ),
                  ),
                  itemBuilder: (_) => AdminStatusFilter.values
                      .map(
                        (status) => PopupMenuItem(
                          value: status,
                          child: Text(
                            status.label,
                            style: TextStyle(
                              fontWeight: _statusFilter == status
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: _statusFilter == status
                                  ? AppTheme.primaryRed
                                  : AppTheme.deepNavy,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),

                const SizedBox(width: 8),

                // Era Filter Menu
                PopupMenuButton<String>(
                  tooltip: 'Filter Era Perjuangan',
                  initialValue: _selectedEra,
                  onSelected: (era) => setState(() => _selectedEra = era),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _selectedEra != 'Semua'
                          ? AppTheme.primaryRed.withValues(alpha: 0.1)
                          : Colors.white,
                      border: Border.all(
                        color: _selectedEra != 'Semua'
                            ? AppTheme.primaryRed
                            : Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history_edu_rounded,
                          size: 14,
                          color: _selectedEra != 'Semua'
                              ? AppTheme.primaryRed
                              : AppTheme.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _selectedEra == 'Semua'
                              ? 'Semua Era'
                              : (_selectedEra.length > 18
                                  ? '${_selectedEra.substring(0, 16)}…'
                                  : _selectedEra),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: _selectedEra != 'Semua'
                                ? AppTheme.primaryRed
                                : AppTheme.deepNavy,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 16,
                          color: _selectedEra != 'Semua'
                              ? AppTheme.primaryRed
                              : AppTheme.textMuted,
                        ),
                      ],
                    ),
                  ),
                  itemBuilder: (_) => eras
                      .map(
                        (era) => PopupMenuItem(
                          value: era,
                          child: Text(
                            era,
                            style: TextStyle(
                              fontWeight: _selectedEra == era
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: _selectedEra == era
                                  ? AppTheme.primaryRed
                                  : AppTheme.deepNavy,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),

                const Spacer(),

                // Mode Urutan Aktif
                Text(
                  _sortMode.label.split(' ')[0],
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // 4. Baris Info Hasil Filter
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Menampilkan ${filteredHeroes.length} dari ${allHeroes.length} Pahlawan',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
                if (_isFilterActive)
                  GestureDetector(
                    onTap: _resetAllFilters,
                    child: const Text(
                      'Reset Filter',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryRed,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 5. Daftar Pahlawan
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => controller.loadData(showLoading: false),
              child: filteredHeroes.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.45,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: 56,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 14),
                                  const Text(
                                    'Pahlawan tidak ditemukan',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.deepNavy,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'Tidak ada data yang cocok dengan kata kunci "$_searchQuery".'
                                        : 'Tidak ada data dengan filter yang dipilih.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  OutlinedButton.icon(
                                    onPressed: _resetAllFilters,
                                    icon: const Icon(Icons.refresh_rounded, size: 16),
                                    label: const Text('Reset Pencarian & Filter'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                      itemCount: filteredHeroes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final hero = filteredHeroes[index];
                        final hasQuote = _hasCustomQuote(hero);

                        return Card(
                          margin: EdgeInsets.zero,
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _viewDetail(context, hero),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Foto Pahlawan dengan ClipRRect
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      width: 52,
                                      height: 52,
                                      color: AppTheme.primaryRed.withValues(
                                        alpha: 0.08,
                                      ),
                                      child: heroImage(
                                        hero.photoPath,
                                        width: 52,
                                        height: 52,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  // Konten Deskripsi
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Nama Pahlawan
                                        Text(
                                          hero.name,
                                          style: const TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.deepNavy,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),

                                        const SizedBox(height: 2),

                                        // Asal & Wilayah
                                        Text(
                                          '${hero.regionGroup} • ${hero.fullOrigin}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textMuted,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),

                                        const SizedBox(height: 5),

                                        // Badges: Kutipan & Era
                                        Row(
                                          children: [
                                            // Badge Status Kutipan
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: hasQuote
                                                    ? Colors.green.shade50
                                                    : Colors.amber.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: hasQuote
                                                      ? Colors.green.shade300
                                                      : Colors.amber.shade300,
                                                  width: 0.8,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.format_quote_rounded,
                                                    size: 11,
                                                    color: hasQuote
                                                        ? Colors.green.shade800
                                                        : Colors.amber.shade900,
                                                  ),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    hasQuote
                                                        ? 'Ada Kutipan'
                                                        : 'Kutipan Default',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w600,
                                                      color: hasQuote
                                                          ? Colors.green.shade800
                                                          : Colors.amber.shade900,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            const SizedBox(width: 6),

                                            // Badge Era Singkat
                                            if (hero.struggleEra.isNotEmpty)
                                              Flexible(
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.deepNavy
                                                        .withValues(alpha: 0.06),
                                                    borderRadius:
                                                        BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    hero.struggleEra,
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color: AppTheme.deepNavy,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Aksi Edit & Menu
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 20,
                                      color: AppTheme.deepNavy,
                                    ),
                                    tooltip: 'Edit Data',
                                    onPressed: () => _edit(context, hero),
                                  ),

                                  PopupMenuButton<String>(
                                    icon: const Icon(
                                      Icons.more_vert_rounded,
                                      size: 20,
                                      color: AppTheme.textMuted,
                                    ),
                                    tooltip: 'Menu Aksi',
                                    onSelected: (action) {
                                      if (action == 'detail') {
                                        _viewDetail(context, hero);
                                      } else if (action == 'edit') {
                                        _edit(context, hero);
                                      } else if (action == 'copy_id') {
                                        _copyId(context, hero);
                                      } else if (action == 'delete') {
                                        _delete(context, hero);
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(
                                        value: 'detail',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.visibility_outlined,
                                              size: 18,
                                              color: AppTheme.deepNavy,
                                            ),
                                            SizedBox(width: 8),
                                            Text('Lihat Detail'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.edit_outlined,
                                              size: 18,
                                              color: AppTheme.deepNavy,
                                            ),
                                            SizedBox(width: 8),
                                            Text('Edit Data'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'copy_id',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.copy_rounded,
                                              size: 18,
                                              color: AppTheme.deepNavy,
                                            ),
                                            SizedBox(width: 8),
                                            Text('Salin ID'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuDivider(),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete_outline_rounded,
                                              size: 18,
                                              color: AppTheme.primaryRed,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Hapus',
                                              style: TextStyle(
                                                color: AppTheme.primaryRed,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
