import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pahlawan_nasional/controllers/pahlawan_controller.dart';
import 'package:pahlawan_nasional/models/hero_model.dart';
import 'package:pahlawan_nasional/models/quiz_model.dart';
import 'package:pahlawan_nasional/repositories/hero_repository.dart';
import 'package:pahlawan_nasional/repositories/quiz_repository.dart';
import 'package:pahlawan_nasional/views/screens/hero_favorites_screen.dart';

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
  const mockHero1 = HeroModel(
    id: 'diponegoro_1',
    name: 'Pangeran Diponegoro',
    knownAs: 'Bendara Raden Mas Antawirya',
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

  const mockHero2 = HeroModel(
    id: 'kartini_2',
    name: 'R.A. Kartini',
    knownAs: 'Raden Ajeng Kartini',
    originCity: 'Jepara',
    originProvince: 'Jawa Tengah',
    regionGroup: 'Jawa',
    birthDate: '21 April 1879',
    birthPlace: 'Jepara',
    deathDate: '17 September 1904',
    deathPlace: 'Rembang',
    ageAtDeath: 25,
    photoPath: 'assets/images/kartini.png',
    shortBio: 'Pelopor emansipasi wanita',
    fullBio: 'Biografi...',
    struggleEra: 'Pendidikan & Emansipasi',
    keyContributions: ['Habis Gelap Terbitlah Terang'],
    famousQuote: 'Habis gelap terbitlah terang.',
    quoteContext: 'Surat-surat Kartini',
    decreeNumber: 'Keppres No. 108 Tahun 1964',
    burialPlace: 'Rembang',
  );

  testWidgets('HeroFavoritesScreen shows empty state and list when favorited', (
    WidgetTester tester,
  ) async {
    final controller = PahlawanController(
      heroRepository: FakeHeroRepository([mockHero1, mockHero2]),
      quizRepository: FakeQuizRepository(),
    );
    await controller.loadData();

    await tester.pumpWidget(
      ChangeNotifierProvider<PahlawanController>.value(
        value: controller,
        child: const MaterialApp(home: HeroFavoritesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Initial state: empty
    expect(find.text('Belum Ada Pahlawan Favorit'), findsOneWidget);

    // Add Diponegoro to favorites
    await controller.toggleFavorite('diponegoro_1');
    await tester.pumpAndSettle();

    // Now Diponegoro should appear
    expect(find.text('Belum Ada Pahlawan Favorit'), findsNothing);
    expect(find.text('Pangeran Diponegoro'), findsOneWidget);
    expect(find.text('R.A. Kartini'), findsNothing);

    // Toggle Diponegoro off
    await controller.toggleFavorite('diponegoro_1');
    await tester.pumpAndSettle();

    // Returns to empty state
    expect(find.text('Belum Ada Pahlawan Favorit'), findsOneWidget);
  });

  testWidgets('HeroFavoritesScreen toggles between gallery grid and list mode and searches', (
    WidgetTester tester,
  ) async {
    final controller = PahlawanController(
      heroRepository: FakeHeroRepository([mockHero1, mockHero2]),
      quizRepository: FakeQuizRepository(),
    );
    await controller.loadData();
    await controller.toggleFavorite('diponegoro_1');
    await controller.toggleFavorite('kartini_2');

    await tester.pumpWidget(
      ChangeNotifierProvider<PahlawanController>.value(
        value: controller,
        child: const MaterialApp(home: HeroFavoritesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Both heroes visible in gallery
    expect(find.text('Pangeran Diponegoro'), findsOneWidget);
    expect(find.text('R.A. Kartini'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);

    // Toggle to list mode
    await tester.tap(find.byTooltip('Ubah ke Mode Daftar'));
    await tester.pumpAndSettle();
    expect(find.byType(ListView), findsWidgets);
    expect(find.text('Pangeran Diponegoro'), findsOneWidget);

    // Toggle back to gallery mode
    await tester.tap(find.byTooltip('Ubah ke Mode Galeri'));
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsOneWidget);

    // Search for Kartini
    await tester.enterText(find.byType(TextField), 'Kartini');
    await tester.pumpAndSettle();
    expect(find.text('R.A. Kartini'), findsOneWidget);
    expect(find.text('Pangeran Diponegoro'), findsNothing);
  });
}
