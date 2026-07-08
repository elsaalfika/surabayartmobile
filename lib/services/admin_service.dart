import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

class AdminService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<ProfileModel>> getUsersByRole(String role) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('role', role)
        .order('tanggal_daftar', ascending: false);
    return (data as List).map((e) => ProfileModel.fromJson(e)).toList();
  }

  Future<int> countByRole(String role) async {
    final data = await _client.from('profiles').select('id').eq('role', role);
    return (data as List).length;
  }

  Future<void> toggleStatusAkun(String userId, String newStatus) async {
    await _client
        .from('profiles')
        .update({'status_akun': newStatus})
        .eq('id', userId);
  }

  Future<void> updateProfileByAdmin({
    required String userId,
    String? namaUser,
    String? namaInstansi,
    String? nik,
    String? telpUser,
  }) async {
    final updates = <String, dynamic>{};
    if (namaUser != null) updates['nama_user'] = namaUser;
    if (namaInstansi != null) updates['nama_instansi'] = namaInstansi;
    if (nik != null) updates['nik'] = nik;
    if (telpUser != null) updates['telp_user'] = telpUser;

    if (updates.isNotEmpty) {
      await _client.from('profiles').update(updates).eq('id', userId);
    }
  }
}