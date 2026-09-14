import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/game_controller.dart';
import '../../models/match_model.dart';
import '../widgets/score_area.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  void _showWinnerDialog(BuildContext context, GameController controller) {
    final match = controller.match;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text('${match.winnerName} Menang!'),
        content: Text(
          'Skor akhir: ${match.player1Score} - ${match.player2Score}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              controller.backToSetup();
              Navigator.of(context).pop(); // kembali ke SettingsScreen
            },
            child: const Text('Ubah Setting'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              controller.rematch();
            },
            child: const Text('Main Lagi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final match = controller.match;

    if (match.status == MatchStatus.finished) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) _showWinnerDialog(context, controller);
      });
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    'Target skor: ${match.maxScore}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  // Muncul otomatis begitu kedua skor sama-sama
                  // menyentuh maxScore-1 (hanya kalau deuce aktif).
                  if (match.isDeuce)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'DEUCE!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: ScoreArea(
                      playerLabel: match.player1Name,
                      score: match.player1Score,
                      color: Colors.blue.shade600,
                      onTap: () => controller.addPoint(1),
                    ),
                  ),
                  const VerticalDivider(width: 2, color: Colors.white),
                  Expanded(
                    child: ScoreArea(
                      playerLabel: match.player2Name,
                      score: match.player2Score,
                      color: Colors.red.shade600,
                      onTap: () => controller.addPoint(2),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}