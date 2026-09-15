/// MODEL -- satu baris riwayat pertandingan yang sudah selesai.
/// Dibuat terpisah dari MatchModel karena MatchModel merepresentasikan
/// pertandingan yang SEDANG berjalan, sementara ini snapshot hasil
/// akhir yang sudah tidak berubah lagi.
class MatchHistoryEntry {
  final String player1Name;
  final String player2Name;
  final int player1Score;
  final int player2Score;
  final int maxScore;
  final bool useDeuce;
  final DateTime playedAt;

  const MatchHistoryEntry({
    required this.player1Name,
    required this.player2Name,
    required this.player1Score,
    required this.player2Score,
    required this.maxScore,
    required this.useDeuce,
    required this.playedAt,
  });

  String get winnerName =>
      player1Score > player2Score ? player1Name : player2Name;

  String get loserName =>
      player1Score > player2Score ? player2Name : player1Name;

  int get winnerScore =>
      player1Score > player2Score ? player1Score : player2Score;

  int get loserScore =>
      player1Score > player2Score ? player2Score : player1Score;
}