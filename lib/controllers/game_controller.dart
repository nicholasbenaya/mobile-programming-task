import 'package:flutter/material.dart';
import '../models/match_model.dart';

/// CONTROLLER (MVC)
///
/// Tempat satu-satunya logic "aturan main" hidup: nambah skor,
/// cek siapa menang (termasuk aturan deuce), reset ronde, dsb.
/// View (SettingsScreen/GameScreen) tidak pernah mengubah skor
/// secara langsung -- selalu lewat method di sini, lalu
/// notifyListeners() memberi tahu View untuk render ulang.
class GameController extends ChangeNotifier {
  MatchModel match = const MatchModel(maxScore: 11);

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

    match = updated.copyWith(status: _checkStatus(updated));
    notifyListeners();
  }

  /// Aturan menang:
  /// - Tanpa deuce: langsung selesai begitu salah satu skor >= maxScore.
  /// - Dengan deuce: harus skor >= maxScore DAN unggul minimal 2 poin
  ///   dari lawan (contoh: 12-10 menang, 11-10 belum, lanjut sampai
  ///   ada yang unggul 2).
  MatchStatus _checkStatus(MatchModel m) {
    final higher =
        m.player1Score > m.player2Score ? m.player1Score : m.player2Score;
    final diff = (m.player1Score - m.player2Score).abs();

    final isOver =
        m.useDeuce ? (higher >= m.maxScore && diff >= 2) : higher >= m.maxScore;

    return isOver ? MatchStatus.finished : MatchStatus.playing;
  }

  /// Main lagi dengan pengaturan (nama, maxScore, deuce) yang sama.
  void rematch() {
    match = match.copyWith(
      player1Score: 0,
      player2Score: 0,
      status: MatchStatus.playing,
    );
    notifyListeners();
  }

  /// Balik ke SettingsScreen untuk ubah pengaturan.
  void backToSetup() {
    match = match.copyWith(status: MatchStatus.setup);
    notifyListeners();
  }
}