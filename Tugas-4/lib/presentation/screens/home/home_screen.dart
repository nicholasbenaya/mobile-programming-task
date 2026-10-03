import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/record_category.dart';
import '../../../data/services/export_service.dart';
import '../../../providers/records_provider.dart';
import '../../navigation/app_routes.dart';
import '../../widgets/category_style.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/record_card.dart';
import '../../widgets/stat_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _export(BuildContext context) async {
    final records = context.read<RecordsProvider>().records;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<ExportService>().shareCsv(records);
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Gagal mengekspor data')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecordsProvider>();
    final items = provider.visible;

    return RefreshIndicator(
      onRefresh: provider.load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            title: const Text('SensorLog', style: TextStyle(fontWeight: FontWeight.w800)),
            actions: [
              IconButton(
                tooltip: 'Ekspor CSV',
                icon: const Icon(Icons.ios_share_rounded),
                onPressed: provider.records.isEmpty ? null : () => _export(context),
              ),
              const SizedBox(width: 4),
            ],
          ),
          SliverToBoxAdapter(child: _Header(provider: provider)),
          if (provider.loading && provider.records.isEmpty)
            const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator()))
          else if (provider.error != null && provider.records.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.cloud_off_rounded,
                title: 'Gagal memuat',
                message: provider.error!,
                actionLabel: 'Coba lagi',
                onAction: provider.load,
              ),
            )
          else if (items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: provider.records.isEmpty ? Icons.add_a_photo_rounded : Icons.search_off_rounded,
                title: provider.records.isEmpty ? 'Belum ada catatan' : 'Tidak ditemukan',
                message: provider.records.isEmpty
                    ? 'Ketuk tombol kamera di bawah untuk membuat catatan lapangan pertama.'
                    : 'Coba ubah kata kunci atau filter kategori.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              sliver: SliverList.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) => RecordCard(
                  record: items[i],
                  onTap: () => AppRoutes.openDetail(context, items[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.provider});
  final RecordsProvider provider;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: StatCard(label: 'Total catatan', value: '${provider.records.length}', icon: Icons.folder_rounded)),
              const SizedBox(width: 10),
              Expanded(child: StatCard(label: 'Hari ini', value: '${provider.todayCount}', icon: Icons.today_rounded)),
              const SizedBox(width: 10),
              Expanded(child: StatCard(label: '7 hari', value: '${provider.weekCount}', icon: Icons.date_range_rounded)),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: provider.setQuery,
            decoration: const InputDecoration(
              hintText: 'Cari judul atau catatan…',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(label: 'Semua', selected: provider.filter == null, onTap: () => provider.setFilter(null)),
                for (final c in RecordCategory.values)
                  _FilterChip(
                    label: c.label,
                    icon: c.icon,
                    selected: provider.filter == c,
                    onTap: () => provider.setFilter(provider.filter == c ? null : c),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap, this.icon});
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        avatar: icon == null ? null : Icon(icon, size: 16),
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
      ),
    );
  }
}
