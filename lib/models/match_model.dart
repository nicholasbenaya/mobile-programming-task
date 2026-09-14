/// Status pertandingan saat ini.
///
/// `setup`    -> user sedang mengatur max score, belum mulai main.
/// `playing`  -> pertandingan berjalan, tap masih dihitung.
/// `finished` -> salah satu pemain sudah mencapai max score
///               (dengan syarat deuce terpenuhi jika diaktifkan).
enum MatchStatus { setup, playing, finished }

/// MODEL (MVC)
///
/// Kelas ini murni menyimpan DATA pertandingan. Tidak ada logic
/// "nambah skor" atau "cek siapa menang" di sini -- itu tugas
/// Controller. Model hanya bertanggung jawab merepresentasikan
/// bentuk data secara konsisten.
///
/// Dibuat immutable (semua field `final`) dan pakai `copyWith`
/// supaya setiap perubahan state menghasilkan objek baru yang jelas
/// -- pola umum di Flutter agar gampang di-debug (bisa lihat histori
/// state) dan menghindari bug "state berubah diam-diam" di tempat
/// yang tidak terduga.
class MatchModel {
  final String player1Name;
  final String player2Name;
  final int maxScore;
  final bool useDeuce;
  final int player1Score;
  final int player2Score;
  final MatchStatus status;

  const MatchModel({
    this.player1Name = 'Pemain 1',
    this.player2Name = 'Pemain 2',
    required this.maxScore,
    this.useDeuce = true,
    this.player1Score = 0,
    this.player2Score = 0,
    this.status = MatchStatus.setup,
  });

  /// Pemenang saat ini: 1, 2, atau null kalau belum ada/belum selesai.
  /// Dengan deuce aktif, cukup "skor >= maxScore" TIDAK otomatis menang --
  /// Controller yang menentukan status `finished` (lihat _checkWinner di
  /// GameController), getter ini hanya membaca hasilnya.
  int? get winner {
    if (status != MatchStatus.finished) return null;
    if (player1Score > player2Score) return 1;
    if (player2Score > player1Score) return 2;
    return null;
  }

  /// Nama pemenang, dipakai langsung di dialog GameScreen.
  String? get winnerName {
    final w = winner;
    if (w == null) return null;
    return w == 1 ? player1Name : player2Name;
  }

  /// True saat kedua skor sudah sama-sama menyentuh ambang (maxScore-1)
  /// dan masih seri -- dipakai GameScreen buat nampilin label "Deuce!".
  bool get isDeuce {
    if (!useDeuce) return false;
    return player1Score >= maxScore - 1 &&
        player2Score >= maxScore - 1 &&
        player1Score == player2Score;
  }

  MatchModel copyWith({
    String? player1Name,
    String? player2Name,
    int? maxScore,
    bool? useDeuce,
    int? player1Score,
    int? player2Score,
    MatchStatus? status,
  }) {
    return MatchModel(
      player1Name: player1Name ?? this.player1Name,
      player2Name: player2Name ?? this.player2Name,
      maxScore: maxScore ?? this.maxScore,
      useDeuce: useDeuce ?? this.useDeuce,
      player1Score: player1Score ?? this.player1Score,
      player2Score: player2Score ?? this.player2Score,
      status: status ?? this.status,
    );
  }
}