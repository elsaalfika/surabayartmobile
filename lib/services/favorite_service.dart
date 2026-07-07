import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pameran_model.dart';

class FavoriteService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<PameranModel>> getFavoritePameran(String idCustomer) async {
    final data = await _client
        .from('favorite')
        .select('pameran(*)')
        .eq('id_customer', idCustomer);

    return (data as List)
        .where((e) => e['pameran'] != null)
        .map((e) => PameranModel.fromJson(e['pameran']))
        .toList();
  }

  Future<bool> isFavorite(String idCustomer, String idPameran) async {
    final data = await _client
        .from('favorite')
        .select('id_favorite')
        .eq('id_customer', idCustomer)
        .eq('id_pameran', idPameran)
        .maybeSingle();
    return data != null;
  }

  Future<void> addFavorite(String idCustomer, String idPameran) async {
    await _client.from('favorite').insert({
      'id_customer': idCustomer,
      'id_pameran': idPameran,
    });
  }

  Future<void> removeFavorite(String idCustomer, String idPameran) async {
    await _client
        .from('favorite')
        .delete()
        .eq('id_customer', idCustomer)
        .eq('id_pameran', idPameran);
  }

  Future<void> toggleFavorite(String idCustomer, String idPameran) async {
    final fav = await isFavorite(idCustomer, idPameran);
    if (fav) {
      await removeFavorite(idCustomer, idPameran);
    } else {
      await addFavorite(idCustomer, idPameran);
    }
  }
}