import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/pahlawan_controller.dart';
import '../../models/hero_model.dart';
import '../../utils/app_theme.dart';
import 'hero_editor_screen.dart';

class HeroAdminScreen extends StatelessWidget {
  const HeroAdminScreen({super.key});

  Future<void> _create(BuildContext context) async {
    final values = await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute(builder: (_) => const HeroEditorScreen()),
    );
    if (values == null || !context.mounted) return;
    await context.read<PahlawanController>().createHero(values);
  }

  Future<void> _edit(BuildContext context, HeroModel hero) async {
    final values = await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute(builder: (_) => HeroEditorScreen(hero: hero)),
    );
    if (values == null || !context.mounted) return;
    await context.read<PahlawanController>().updateHero(hero.id, values);
  }

  Future<void> _delete(BuildContext context, HeroModel hero) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus pahlawan?'),
        content: Text('Data ${hero.name} akan dihapus dari database.'),
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
    await context.read<PahlawanController>().deleteHero(hero.id);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PahlawanController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Data Pahlawan')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context),
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah'),
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.loadData(showLoading: false),
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: controller.allHeroes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final hero = controller.allHeroes[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryRed.withValues(alpha: 0.12),
                  child: Text('${index + 1}'),
                ),
                title: Text(
                  hero.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text('${hero.regionGroup} - ${hero.fullOrigin}'),
                trailing: PopupMenuButton<String>(
                  tooltip: 'Aksi data',
                  onSelected: (action) {
                    if (action == 'edit') _edit(context, hero);
                    if (action == 'delete') _delete(context, hero);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Hapus')),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
