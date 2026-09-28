import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pahlawan_nasional/controllers/pahlawan_controller.dart';
import 'package:pahlawan_nasional/models/hero_model.dart';
import 'package:pahlawan_nasional/models/quiz_model.dart';
import 'package:pahlawan_nasional/repositories/hero_repository.dart';
import 'package:pahlawan_nasional/repositories/quiz_repository.dart';
import 'package:pahlawan_nasional/views/screens/main_navigation_screen.dart';

class FakeHeroRepository extends HeroRepository {
  final List<HeroModel> heroes;
  FakeHeroRepository(this.heroes);

  @override
  Future<List<HeroModel>> getAllHeroes() async => heroes;

  @override
  Future<Set<String>> getFavoriteIds() async => {};
}

class FakeQuizRepository extends QuizRepository {
  @override
  Future<List<QuizQuestion>> getAllQuestions() async => [];
}

void main() {
  const mockHero = HeroModel(
    id: 'diponegoro_1',
    name: 'Pangeran Diponegoro',
    knownAs: 'Pangeran Diponegoro',
    originCity: 'Yogyakarta',
    originProvince: 'DI Yogyakarta',
    regionGroup: 'Jawa',
    birthDate: '11 November 1785',
    birthPlace: 'Yogyakarta',
    deathDate: '8 Januari 1855',
    deathPlace: 'Makassar',
    ageAtDeath: 69,
    photoPath: 'assets/images/diponegoro.png',
    shortBio: 'Pemimpin Perang Jawa',
    fullBio: 'Biografi...',
    struggleEra: 'Perlawanan Kerajaan / Daerah',
    keyContributions: ['Perang Jawa'],
    famousQuote: 'Hidup dan mati ada dalam tangan Allah.',
    quoteContext: 'Perang Jawa',
    decreeNumber: 'Keppres No. 087/TK/1973',
    burialPlace: 'Makassar',
  );

  testWidgets('MainNavigationScreen mounts and switches tabs without error', (
    WidgetTester tester,
  ) async {
    final controller = PahlawanController(
      heroRepository: FakeHeroRepository([mockHero]),
      quizRepository: FakeQuizRepository(),
    );
    await controller.loadData();

    await tester.pumpWidget(
      ChangeNotifierProvider<PahlawanController>.value(
        value: controller,
        child: const MaterialApp(home: MainNavigationScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Dashboard is visible
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Pahlawan Nasional'), findsWidgets);

    // Switch to 'Daftar' tab
    await tester.tap(find.text('Daftar'));
    await tester.pumpAndSettle();
    expect(find.text('Daftar Pahlawan Nasional'), findsOneWidget);

    // Switch to 'Galeri' tab
    await tester.tap(find.text('Galeri'));
    await tester.pumpAndSettle();
    expect(find.text('Galeri Foto Pahlawan'), findsOneWidget);

    // Switch to 'Kuis' tab
    await tester.tap(find.text('Kuis'));
    await tester.pumpAndSettle();

    // Switch back to 'Daftar' tab
    await tester.tap(find.text('Daftar'));
    await tester.pumpAndSettle();
    expect(find.text('Daftar Pahlawan Nasional'), findsOneWidget);
  });

  testWidgets('Quick search from Dashboard carries state and filters Daftar tab', (
    WidgetTester tester,
  ) async {
    final controller = PahlawanController(
      heroRepository: FakeHeroRepository([mockHero]),
      quizRepository: FakeQuizRepository(),
    );
    await controller.loadData();

    await tester.pumpWidget(
      ChangeNotifierProvider<PahlawanController>.value(
        value: controller,
        child: const MaterialApp(home: MainNavigationScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // On Dashboard: find the search TextField and enter Diponegoro
    final searchInput = find.byType(TextField);
    expect(searchInput, findsWidgets);

    await tester.enterText(searchInput.first, 'Diponegoro');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    // Verify automatically navigated to Daftar tab
    expect(find.text('Daftar Pahlawan Nasional'), findsOneWidget);
    expect(find.text('Pangeran Diponegoro'), findsWidgets);
    expect(find.text('Pencarian: "Diponegoro"'), findsOneWidget);

    // Verify search bar in Daftar contains Diponegoro
    final daftarSearchField = tester.widget<TextField>(find.byType(TextField).first);
    expect(daftarSearchField.controller?.text, 'Diponegoro');
  });
}
