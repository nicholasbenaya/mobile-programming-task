import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../controllers/game_controller.dart';
import '../../models/match_history_entry.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final history = controller.history;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pertandingan'),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Hapus semua riwayat',
              onPressed: () => _confirmClear(context, controller),
            ),
        ],
      ),
      body: history.isEmpty
          ? const Center(
              child: Text(
                'Belum ada pertandingan yang selesai.',
                style: TextStyle(color: Colors.black54),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: history.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) =>
                  _HistoryTile(entry: history[index]),
            ),
    );
  }

  void _confirmClear(BuildContext context, GameController controller) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus riwayat?'),
        content: const Text('Semua catatan pertandingan akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              controller.clearHistory();
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final MatchHistoryEntry entry;

  const _HistoryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('d MMM y, HH:mm').format(entry.playedAt);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${entry.winnerName} 🏆  vs  ${entry.loserName}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${entry.winnerScore} - ${entry.loserScore}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Target ${entry.maxScore}'
              '${entry.useDeuce ? " • Deuce" : ""}  •  $dateStr',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}