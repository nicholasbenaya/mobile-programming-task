import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/hero_model.dart';
import '../services/supabase_service.dart';

/// Semua panggilan API untuk data pahlawan & favorit ada di sini.
/// Supabase otomatis membuat REST API dari tabel, sehingga
///   client.from('heroes').select()
/// sama dengan request:  GET https://<project>.supabase.co/rest/v1/heroes?select=*
class HeroRepository {
  SupabaseClient get _client => SupabaseService.client;

  /// GET semua pahlawan beserta kontribusinya (join tabel sekaligus).
  Future<List<HeroModel>> getAllHeroes() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('heroes')
        .select('*, hero_contributions(contribution, sort_order)')
        .order('sort_order', ascending: true);

    return rows.map(HeroModel.fromMap).toList();
  }

  /// GET 1 pahlawan berdasarkan id.
  Future<HeroModel?> getHeroById(String id) async {
    final Map<String, dynamic>? row = await _client
        .from('heroes')
        .select('*, hero_contributions(contribution, sort_order)')
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : HeroModel.fromMap(row);
  }

  // ------------------------- FAVORIT -------------------------

  /// GET favorit milik pengguna yang sedang login (dibatasi oleh RLS).
  Future<Set<String>> getFavoriteIds() async {
    await SupabaseService.ensureSignedIn();
    final List<Map<String, dynamic>> rows =
        await _client.from('favorites').select('hero_id');
    return rows.map((r) => r['hero_id'] as String).toSet();
  }

  /// POST favorit baru. user_id diisi otomatis oleh database (auth.uid()).
  Future<void> addFavorite(String heroId) async {
    await SupabaseService.ensureSignedIn();
    await _client.from('favorites').upsert(
      {'hero_id': heroId},
      onConflict: 'user_id,hero_id',
      ignoreDuplicates: true,
    );
  }

  /// DELETE favorit.
  Future<void> removeFavorite(String heroId) async {
    final userId = await SupabaseService.ensureSignedIn();
    await _client
        .from('favorites')
        .delete()
        .eq('user_id', userId)
        .eq('hero_id', heroId);
  }
}
