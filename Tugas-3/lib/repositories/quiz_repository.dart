import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/quiz_model.dart';
import '../services/supabase_service.dart';

/// Panggilan API untuk soal kuis.
class QuizRepository {
  SupabaseClient get _client => SupabaseService.client;

  /// GET semua soal + pilihan jawabannya (urut q1, q2, ... q10).
  Future<List<QuizQuestion>> getAllQuestions() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('quiz_questions')
        .select('*, quiz_options(option_index, option_text)')
        .order('sort_order', ascending: true);

    return rows.map(QuizQuestion.fromMap).toList();
  }
}
