import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/pahlawan_controller.dart';
import '../../utils/app_theme.dart';

class SearchFilterBar extends StatefulWidget {
  final bool showFilterChips;

  const SearchFilterBar({super.key, this.showFilterChips = true});

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends State<SearchFilterBar> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    final currentQuery = context.read<PahlawanController>().searchQuery;
    _textController = TextEditingController(text: currentQuery);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PahlawanController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kolom Input Pencarian
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _textController,
            onChanged: (val) => controller.setSearchQuery(val),
            decoration: InputDecoration(
              hintText: 'Cari pahlawan, daerah asal, atau peristiwa...',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryRed),
              suffixIcon: _textController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _textController.clear();
                        controller.setSearchQuery('');
                      },
                    )
                  : PopupMenuButton<HeroSortMode>(
                      icon: const Icon(Icons.tune_rounded, color: AppTheme.deepNavy),
                      tooltip: 'Urutkan Daftar',
                      onSelected: (mode) => controller.setSortMode(mode),
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: HeroSortMode.nameAsc,
                          child: Text('Nama (A – Z)'),
                        ),
                        const PopupMenuItem(
                          value: HeroSortMode.nameDesc,
                          child: Text('Nama (Z – A)'),
                        ),
                        const PopupMenuItem(
                          value: HeroSortMode.birthYearAsc,
                          child: Text('Tahun Lahir (Tertua)'),
                        ),
                        const PopupMenuItem(
                          value: HeroSortMode.birthYearDesc,
                          child: Text('Tahun Lahir (Termuda)'),
                        ),
                      ],
                    ),
            ),
          ),
        ),

        // Filter Chips Wilayah
        if (widget.showFilterChips)
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: controller.availableRegions.length,
              itemBuilder: (context, index) {
                final region = controller.availableRegions[index];
                final isSelected = controller.selectedRegion == region;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(region),
                    selected: isSelected,
                    onSelected: (_) => controller.setSelectedRegion(region),
                    selectedColor: AppTheme.primaryRed,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? AppTheme.primaryRed : Colors.grey.shade300,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.deepNavy,
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                    checkmarkColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
