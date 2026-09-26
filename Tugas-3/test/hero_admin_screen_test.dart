import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pahlawan_nasional/controllers/pahlawan_controller.dart';
import 'package:pahlawan_nasional/models/hero_model.dart';
import 'package:pahlawan_nasional/models/quiz_model.dart';
import 'package:pahlawan_nasional/repositories/hero_repository.dart';
import 'package:pahlawan_nasional/repositories/quiz_repository.dart';
import 'package:pahlawan_nasional/views/screens/hero_admin_screen.dart';

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
  final mockHeroes = [
    const HeroModel(
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
      fullBio: 'Biografi Diponegoro...',
      struggleEra: 'Perlawanan Kerajaan / Daerah',
      keyContributions: ['Perang Jawa'],
      famousQuote: 'Hidup dan mati ada dalam tangan Allah.',
      quoteContext: 'Perang Jawa',
      decreeNumber: 'Keppres No. 087/TK/1973',
      burialPlace: 'Makassar',
    ),
    const HeroModel(
      id: 'hasanuddin_2',
      name: 'Sultan Hasanuddin',
      knownAs: 'Ayam Jantan dari Timur',
      originCity: 'Gowa',
      originProvince: 'Sulawesi Selatan',
      regionGroup: 'Sulawesi',
      birthDate: '12 Januari 1631',
      birthPlace: 'Makassar',
      deathDate: '12 Juni 1670',
      deathPlace: 'Gowa',
      ageAtDeath: 39,
      photoPath: 'assets/images/hasanuddin.png',
      shortBio: 'Sultan Gowa ke-16',
      fullBio: 'Biografi Hasanuddin...',
      struggleEra: 'Perlawanan Kerajaan / Daerah',
      keyContributions: ['Perang Makassar'],
      famousQuote: 'Kutipan khusus belum tersedia dalam dataset.',
      quoteContext: '',
      decreeNumber: 'Keppres No. 087/TK/1973',
      burialPlace: 'Gowa',
    ),
    const HeroModel(
      id: 'kartini_3',
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
      fullBio: 'Biografi Kartini...',
      struggleEra: 'Pendidikan & Emansipasi',
      keyContributions: ['Habis Gelap Terbitlah Terang'],
      famousQuote: 'Habis gelap terbitlah terang.',
      quoteContext: 'Surat-surat Kartini',
      decreeNumber: 'Keppres No. 108 Tahun 1964',
      burialPlace: 'Rembang',
    ),
  ];

  testWidgets('HeroAdminScreen displays heroes, search bar, and filter chips', (
    WidgetTester tester,
  ) async {
    final controller = PahlawanController(
      heroRepository: FakeHeroRepository(mockHeroes),
      quizRepository: FakeQuizRepository(),
    );
    await controller.loadData();

    await tester.pumpWidget(
      ChangeNotifierProvider<PahlawanController>.value(
        value: controller,
        child: const MaterialApp(home: HeroAdminScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title and search bar
    expect(find.text('Kelola Data Pahlawan'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Verify all mock heroes are displayed
    expect(find.text('Pangeran Diponegoro'), findsOneWidget);
    expect(find.text('Sultan Hasanuddin'), findsOneWidget);
    expect(find.text('R.A. Kartini'), findsOneWidget);

    // Test Search Functionality: Search "Diponegoro"
    await tester.enterText(find.byType(TextField), 'Diponegoro');
    await tester.pumpAndSettle();

    expect(find.text('Pangeran Diponegoro'), findsOneWidget);
    expect(find.text('Sultan Hasanuddin'), findsNothing);
    expect(find.text('R.A. Kartini'), findsNothing);

    // Test Clear Search
    await tester.tap(find.byIcon(Icons.clear_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Pangeran Diponegoro'), findsOneWidget);
    expect(find.text('Sultan Hasanuddin'), findsOneWidget);
    expect(find.text('R.A. Kartini'), findsOneWidget);

    // Test Region Filter: Tap 'Sulawesi'
    await tester.tap(find.widgetWithText(FilterChip, 'Sulawesi'));
    await tester.pumpAndSettle();

    expect(find.text('Sultan Hasanuddin'), findsOneWidget);
    expect(find.text('Pangeran Diponegoro'), findsNothing);
    expect(find.text('R.A. Kartini'), findsNothing);

    // Test Reset Filter
    await tester.tap(find.text('Reset Filter'));
    await tester.pumpAndSettle();

    expect(find.text('Pangeran Diponegoro'), findsOneWidget);
    expect(find.text('Sultan Hasanuddin'), findsOneWidget);
    expect(find.text('R.A. Kartini'), findsOneWidget);
  });
}
