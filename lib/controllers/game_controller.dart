import 'package:flutter/material.dart';
import '../models/match_model.dart';
import '../models/match_history_entry.dart';

class GameController extends ChangeNotifier {
  MatchModel match = const MatchModel(maxScore: 11);

  // Riwayat pertandingan yang sudah selesai, terbaru di posisi awal.
  // Simpan sebagai unmodifiable view supaya View tidak bisa
  // mengubahnya langsung -- harus lewat method Controller.
  final List<MatchHistoryEntry> _history = [];
  List<MatchHistoryEntry> get history => List.unmodifiable(_history);

  void setMaxScoreAndStart(
    int maxScore, {
    required String player1Name,
    required String player2Name,
    required bool useDeuce,
  }) {
    match = MatchModel(
      player1Name: player1Name,
      player2Name: player2Name,
      maxScore: maxScore,
      useDeuce: useDeuce,
      status: MatchStatus.playing,
    );
    notifyListeners();
  }

  void addPoint(int player) {
    if (match.status != MatchStatus.playing) return;

    final updated = match.copyWith(
      player1Score:
          player == 1 ? match.player1Score + 1 : match.player1Score,
      player2Score:
          player == 2 ? match.player2Score + 1 : match.player2Score,
    );

    final newStatus = _checkStatus(updated);
    match = updated.copyWith(status: newStatus);

    if (newStatus == MatchStatus.finished) {
      _saveToHistory(match);
    }

    notifyListeners();
  }

  void _saveToHistory(MatchModel m) {
    _history.insert(
      0,
      MatchHistoryEntry(
        player1Name: m.player1Name,
        player2Name: m.player2Name,
        player1Score: m.player1Score,
        player2Score: m.player2Score,
        maxScore: m.maxScore,
        useDeuce: m.useDeuce,
        playedAt: DateTime.now(),
      ),
    );
  }

  MatchStatus _checkStatus(MatchModel m) {
    final higher =
        m.player1Score > m.player2Score ? m.player1Score : m.player2Score;
    final diff = (m.player1Score - m.player2Score).abs();

    final isOver =
        m.useDeuce ? (higher >= m.maxScore && diff >= 2) : higher >= m.maxScore;

    return isOver ? MatchStatus.finished : MatchStatus.playing;
  }

  void rematch() {
    match = match.copyWith(
      player1Score: 0,
      player2Score: 0,
      status: MatchStatus.playing,
    );
    notifyListeners();
  }

  void backToSetup() {
    match = match.copyWith(status: MatchStatus.setup);
    notifyListeners();
  }

  /// Opsional: bersihkan semua riwayat (misal tombol "Hapus Riwayat").
  void clearHistory() {
    _history.clear();
    notifyListeners();
  }
}