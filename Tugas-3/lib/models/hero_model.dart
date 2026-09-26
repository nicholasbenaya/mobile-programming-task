class HeroModel {
  final String id;
  final String name;
  final String knownAs;
  final String originCity;
  final String originProvince;
  final String regionGroup; // Jawa, Sumatera, Maluku, Sulawesi, Bali & Nusa, Papua
  final String birthDate;
  final String birthPlace;
  final String deathDate;
  final String deathPlace;
  final int ageAtDeath;
  final String photoPath;
  final String shortBio;
  final String fullBio;
  final String struggleEra; // e.g. Pergerakan Nasional, Revolusi Kemerdekaan, dsb.
  final List<String> keyContributions;
  final String famousQuote;
  final String quoteContext;
  final String decreeNumber;
  final String burialPlace;

  const HeroModel({
    required this.id,
    required this.name,
    required this.knownAs,
    required this.originCity,
    required this.originProvince,
    required this.regionGroup,
    required this.birthDate,
    required this.birthPlace,
    required this.deathDate,
    required this.deathPlace,
    required this.ageAtDeath,
    required this.photoPath,
    required this.shortBio,
    required this.fullBio,
    required this.struggleEra,
    required this.keyContributions,
    required this.famousQuote,
    required this.quoteContext,
    required this.decreeNumber,
    required this.burialPlace,
  });

  String get lifeTimeYears {
    final b = RegExp(r'\b\d{4}\b').firstMatch(birthDate)?.group(0) ?? birthDate;
    final d = RegExp(r'\b\d{4}\b').firstMatch(deathDate)?.group(0) ?? deathDate;
    return '$b – $d';
  }

  String get fullOrigin => '$originCity, $originProvince';

  // ================= KONVERSI DARI / KE API =================

  /// Membuat HeroModel dari JSON hasil API Supabase (tabel `heroes`).
  /// Kolom `hero_contributions` berisi hasil join ke tabel kontribusi.
  factory HeroModel.fromMap(Map<String, dynamic> map) {
    final contributions =
        List<Map<String, dynamic>>.from(map['hero_contributions'] ?? const [])
          ..sort((a, b) =>
              (a['sort_order'] as int).compareTo(b['sort_order'] as int));

    return HeroModel(
      id: map['id'] as String,
      name: map['name'] as String,
      knownAs: map['known_as'] as String,
      originCity: map['origin_city'] as String,
      originProvince: map['origin_province'] as String,
      regionGroup: map['region_group'] as String,
      birthDate: map['birth_date'] as String,
      birthPlace: map['birth_place'] as String,
      deathDate: map['death_date'] as String,
      deathPlace: map['death_place'] as String,
      ageAtDeath: map['age_at_death'] as int,
      photoPath: map['photo_path'] as String,
      shortBio: map['short_bio'] as String,
      fullBio: map['full_bio'] as String,
      struggleEra: map['struggle_era'] as String,
      keyContributions:
          contributions.map((c) => c['contribution'] as String).toList(),
      famousQuote: map['famous_quote'] as String,
      quoteContext: map['quote_context'] as String,
      decreeNumber: map['decree_number'] as String,
      burialPlace: map['burial_place'] as String,
    );
  }

  /// Mengubah HeroModel menjadi JSON untuk dikirim ke tabel `heroes`
  /// (kontribusi dikirim terpisah ke tabel `hero_contributions`).
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'known_as': knownAs,
      'origin_city': originCity,
      'origin_province': originProvince,
      'region_group': regionGroup,
      'birth_date': birthDate,
      'birth_place': birthPlace,
      'death_date': deathDate,
      'death_place': deathPlace,
      'age_at_death': ageAtDeath,
      'photo_path': photoPath,
      'short_bio': shortBio,
      'full_bio': fullBio,
      'struggle_era': struggleEra,
      'famous_quote': famousQuote,
      'quote_context': quoteContext,
      'decree_number': decreeNumber,
      'burial_place': burialPlace,
    };
  }
}
