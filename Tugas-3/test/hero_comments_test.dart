import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pahlawan_nasional/controllers/pahlawan_controller.dart';
import 'package:pahlawan_nasional/models/comment_model.dart';
import 'package:pahlawan_nasional/models/hero_model.dart';
import 'package:pahlawan_nasional/models/quiz_model.dart';
import 'package:pahlawan_nasional/repositories/hero_repository.dart';
import 'package:pahlawan_nasional/repositories/quiz_repository.dart';
import 'package:pahlawan_nasional/views/screens/hero_detail_screen.dart';

class FakeHeroRepository extends HeroRepository {
  final List<HeroModel> heroes;
  FakeHeroRepository(this.heroes);

  @override
  Future<List<HeroModel>> getAllHeroes() async => heroes;

  @override
  Future<Set<String>> getFavoriteIds() async => {};

  @override
  Future<List<CommentModel>> getComments(String heroId) async => [];

  @override
  Future<CommentModel?> addComment({
    required String heroId,
    required String userName,
    required String content,
  }) async =>
      null;

  @override
  Future<void> deleteComment(String commentId) async {}
}

class FakeQuizRepository extends QuizRepository {
  @override
  Future<List<QuizQuestion>> getAllQuestions() async => [];
}

void main() {
  const sampleHero = HeroModel(
    id: 'soekarno',
    name: 'Ir. Soekarno',
    knownAs: 'Bung Karno',
    originCity: 'Surabaya',
    originProvince: 'Jawa Timur',
    regionGroup: 'Jawa',
    birthDate: '6 Juni 1901',
    birthPlace: 'Surabaya',
    deathDate: '21 Juni 1970',
    deathPlace: 'Jakarta',
    ageAtDeath: 69,
    photoPath: 'assets/images/placeholder.png',
    shortBio: 'Presiden pertama Republik Indonesia.',
    fullBio: 'Ir. Soekarno adalah proklamator kemerdekaan Indonesia.',
    struggleEra: 'Kemerdekaan & Diplomasi',
    keyContributions: ['Proklamasi Kemerdekaan 1945'],
    famousQuote: 'Beri aku 1.000 orang tua, niscaya akan kucabut Semeru dari akarnya.',
    quoteContext: 'Pidato Hari Pahlawan',
    decreeNumber: 'Keppres No. 081/TK/1986',
    burialPlace: 'Blitar, Jawa Timur',
  );

  group('CommentModel Unit Tests', () {
    test('CommentModel serializes and deserializes correctly', () {
      final now = DateTime.now();
      final map = {
        'id': '101',
        'hero_id': 'soekarno',
        'user_name': 'Budi Santoso',
        'content': 'Pahlawan bangsa yang sangat inspiratif!',
        'created_at': now.toIso8601String(),
      };

      final comment = CommentModel.fromMap(map);
      expect(comment.id, '101');
      expect(comment.heroId, 'soekarno');
      expect(comment.userName, 'Budi Santoso');
      expect(comment.content, 'Pahlawan bangsa yang sangat inspiratif!');
      expect(comment.timeAgo, 'Baru saja');

      final serialized = comment.toMap();
      expect(serialized['hero_id'], 'soekarno');
      expect(serialized['user_name'], 'Budi Santoso');
      expect(serialized['content'], 'Pahlawan bangsa yang sangat inspiratif!');
    });

    test('CommentModel fallback name is Pengunjung if empty', () {
      final comment = CommentModel.fromMap({
        'id': '1',
        'hero_id': 'soekarno',
        'user_name': '   ',
        'content': 'Halo',
      });
      expect(comment.userName, 'Pengunjung');
    });
  });

  group('PahlawanController Comments Management', () {
    test('Default seed comments are present for soekarno', () {
      final controller = PahlawanController(
        heroRepository: FakeHeroRepository([sampleHero]),
        quizRepository: FakeQuizRepository(),
      );

      final comments = controller.getCommentsForHero('soekarno');
      expect(comments.isNotEmpty, isTrue);
      expect(controller.getCommentCount('soekarno'), greaterThan(0));
    });

    test('Adding and deleting comments updates state', () async {
      final controller = PahlawanController(
        heroRepository: FakeHeroRepository([sampleHero]),
        quizRepository: FakeQuizRepository(),
      );

      final initialCount = controller.getCommentCount('soekarno');

      await controller.addComment(
        heroId: 'soekarno',
        userName: 'Citra',
        content: 'Terima kasih atas jasa-jasamu, Bung Karno!',
      );

      expect(controller.getCommentCount('soekarno'), initialCount + 1);
      final latestComment = controller.getCommentsForHero('soekarno').first;
      expect(latestComment.userName, 'Citra');
      expect(latestComment.content, 'Terima kasih atas jasa-jasamu, Bung Karno!');

      await controller.deleteComment('soekarno', latestComment.id);
      expect(controller.getCommentCount('soekarno'), initialCount);
    });
  });

  group('HeroDetailScreen Comments UI', () {
    testWidgets('Detail screen can navigate to comments tab and display comments', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = PahlawanController(
        heroRepository: FakeHeroRepository([sampleHero]),
        quizRepository: FakeQuizRepository(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<PahlawanController>.value(
            value: controller,
            child: const HeroDetailScreen(hero: sampleHero),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the Komentar tab
      final komentarTab = find.textContaining('Komentar');
      expect(komentarTab, findsWidgets);

      // Tap on Komentar tab
      await tester.tap(komentarTab.first);
      await tester.pumpAndSettle();

      // Verify that comments UI is shown
      expect(find.text('Pesan & Jejak Doa'), findsOneWidget);
      expect(find.text('Tulis Komentar Baru'), findsOneWidget);
      expect(find.text('Kirim Komentar'), findsOneWidget);

      // Verify seed comment from Ahmad Fauzi is visible
      expect(find.text('Ahmad Fauzi'), findsOneWidget);
    });
  });
}
