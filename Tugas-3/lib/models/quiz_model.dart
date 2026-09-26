class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String heroId;

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.heroId,
  });

  // ================= KONVERSI DARI API =================

  /// Dari JSON hasil API Supabase (tabel `quiz_questions`).
  /// Kolom `quiz_options` berisi hasil join ke tabel pilihan jawaban.
  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    final options =
        List<Map<String, dynamic>>.from(map['quiz_options'] ?? const [])
          ..sort((a, b) =>
              (a['option_index'] as int).compareTo(b['option_index'] as int));

    return QuizQuestion(
      id: map['id'] as String,
      heroId: map['hero_id'] as String,
      question: map['question'] as String,
      options: options.map((o) => o['option_text'] as String).toList(),
      correctIndex: map['correct_index'] as int,
      explanation: map['explanation'] as String,
    );
  }
}
