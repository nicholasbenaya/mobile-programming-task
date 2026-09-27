import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/hero_model.dart';
import '../services/supabase_service.dart';

/// Semua panggilan API untuk data pahlawan & favorit ada di sini.
/// Supabase otomatis membuat REST API dari tabel, sehingga
///   client.from('heroes').select()
/// sama dengan request GET ke URL REST project Supabase.
class HeroRepository {
  SupabaseClient get _client => SupabaseService.client;

  static const _heroSelect = '*, hero_contributions(contribution, sort_order)';

  /// GET semua pahlawan beserta kontribusinya (join tabel sekaligus).
  Future<List<HeroModel>> getAllHeroes() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('heroes')
        .select(_heroSelect)
        .order('sort_order', ascending: true);

    return rows.map(HeroModel.fromMap).toList();
  }

  /// GET 1 pahlawan berdasarkan id.
  Future<HeroModel?> getHeroById(String id) async {
    final Map<String, dynamic>? row = await _client
        .from('heroes')
        .select(_heroSelect)
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : HeroModel.fromMap(row);
  }

  Future<void> createHero(Map<String, String> values) async {
    await _client.from('heroes').insert(_heroPayload(values));
  }

  Future<void> updateHero(String id, Map<String, String> values) async {
    final payload = _heroPayload(values)..remove('id');
    await _client.from('heroes').update(payload).eq('id', id);
  }

  Future<void> deleteHero(String id) async {
    await _client.from('heroes').delete().eq('id', id);
  }

  Map<String, dynamic> _heroPayload(Map<String, String> values) {
    return {
      'id': values['id'],
      'name': values['name'],
      'known_as': values['known_as'],
      'origin_city': values['origin_city'],
      'origin_province': values['origin_province'],
      'region_group': values['region_group'],
      'birth_date': values['birth_date'],
      'birth_place': values['birth_place'],
      'death_date': values['death_date'],
      'death_place': values['death_place'],
      'age_at_death': int.parse(values['age_at_death']!),
      'photo_path': values['photo_path'],
      'short_bio': values['short_bio'],
      'full_bio': values['full_bio'],
      'struggle_era': values['struggle_era'],
      'famous_quote': values['famous_quote'],
      'quote_context': values['quote_context'],
      'decree_number': values['decree_number'],
      'burial_place': values['burial_place'],
    };
  }

  // ------------------------- FAVORIT -------------------------

  /// GET favorit milik pengguna yang sedang login (dibatasi oleh RLS).
  Future<Set<String>> getFavoriteIds() async {
    try {
      final userId = await SupabaseService.ensureSignedIn();
      if (userId == null) return {};
      final List<Map<String, dynamic>> rows = await _client
          .from('favorites')
          .select('hero_id');
      return rows.map((r) => r['hero_id'] as String).toSet();
    } catch (_) {
      return {};
    }
  }

  /// POST favorit baru. user_id diisi otomatis oleh database (auth.uid()).
  Future<void> addFavorite(String heroId) async {
    try {
      final userId = await SupabaseService.ensureSignedIn();
      if (userId == null) return;
      await _client
          .from('favorites')
          .upsert(
            {'hero_id': heroId, 'user_id': userId},
            onConflict: 'user_id,hero_id',
            ignoreDuplicates: true,
          );
    } catch (_) {}
  }

  /// DELETE favorit.
  Future<void> removeFavorite(String heroId) async {
    try {
      final userId = await SupabaseService.ensureSignedIn();
      if (userId == null) return;
      await _client
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('hero_id', heroId);
    } catch (_) {}
  }
}
