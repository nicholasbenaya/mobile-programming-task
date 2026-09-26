import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/pahlawan_controller.dart';
import '../../models/quiz_model.dart';
import '../../utils/app_theme.dart';

class HeroQuizScreen extends StatefulWidget {
  const HeroQuizScreen({super.key});

  @override
  State<HeroQuizScreen> createState() => _HeroQuizScreenState();
}

class _HeroQuizScreenState extends State<HeroQuizScreen> {
  // Soal kuis sekarang diambil dari database melalui controller
  List<QuizQuestion> get _questions =>
      context.read<PahlawanController>().quizQuestions;

  int _currentIndex = 0;
  int? _selectedAnswer;
  bool _answered = false;
  int _score = 0;

  void _answer(int index) {
    if (_answered) return;
    setState(() {
      _selectedAnswer = index;
      _answered = true;
      if (index == _questions[_currentIndex].correctIndex) {
        _score += 10;
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _answered = false;
      });
    } else {
      _showResultDialog();
    }
  }

  void _restartQuiz() {
    setState(() {
      _currentIndex = 0;
      _selectedAnswer = null;
      _answered = false;
      _score = 0;
    });
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.emoji_events_rounded, color: AppTheme.accentGold, size: 28),
            SizedBox(width: 8),
            Text('Hasil Kuis Pahlawan'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Skor Akhir: $_score / ${_questions.length * 10}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryRed,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _score >= 80
                  ? 'Luar biasa! Anda sangat memahami sejarah perjuangan pahlawan bangsa.'
                  : _score >= 50
                      ? 'Bagus! Anda memiliki pengetahuan yang baik tentang para pahlawan nasional.'
                      : 'Teruslah membaca biografi para pahlawan untuk semakin menginspirasi langkahmu!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppTheme.textDark),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _restartQuiz();
            },
            child: const Text('Main Lagi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kuis Wawasan Pahlawan')),
        body: const Center(child: Text('Belum ada soal kuis di database.')),
      );
    }
    final q = _questions[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kuis Wawasan Pahlawan'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Skor: $_score',
                  style: const TextStyle(
                    color: AppTheme.primaryRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pertanyaan ${_currentIndex + 1} dari ${_questions.length}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMuted,
                  ),
                ),
                Text(
                  '${((_currentIndex + 1) / _questions.length * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions.length,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(AppTheme.primaryRed),
              borderRadius: BorderRadius.circular(10),
              minHeight: 8,
            ),
            const SizedBox(height: 24),

            // Question Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                q.question,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.deepNavy,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Options
            Expanded(
              child: ListView.builder(
                itemCount: q.options.length,
                itemBuilder: (context, idx) {
                  final optionText = q.options[idx];
                  Color btnColor = Colors.white;
                  Color textColor = AppTheme.deepNavy;
                  BorderSide border = BorderSide(color: Colors.grey.shade300);

                  if (_answered) {
                    if (idx == q.correctIndex) {
                      btnColor = Colors.green.shade50;
                      border = const BorderSide(color: Colors.green, width: 2);
                      textColor = Colors.green.shade900;
                    } else if (idx == _selectedAnswer) {
                      btnColor = Colors.red.shade50;
                      border = const BorderSide(color: Colors.red, width: 2);
                      textColor = Colors.red.shade900;
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: btnColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: border,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: _answered ? null : () => _answer(idx),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: _answered && idx == q.correctIndex
                                    ? Colors.green
                                    : _answered && idx == _selectedAnswer
                                        ? Colors.red
                                        : Colors.grey.shade200,
                                child: Text(
                                  String.fromCharCode(65 + idx),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _answered && (idx == q.correctIndex || idx == _selectedAnswer)
                                        ? Colors.white
                                        : AppTheme.deepNavy,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  optionText,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Explanation & Next Button
            if (_answered) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Colors.blue, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        q.explanation,
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade900, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _nextQuestion,
                  child: Text(
                    _currentIndex < _questions.length - 1 ? 'Pertanyaan Berikutnya' : 'Lihat Hasil Akhir',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
