import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String namaUser,
    required String role,
    String? namaInstansi,
    String? nik,
  }) async {
    // Semua field dikirim langsung lewat metadata signUp.
    // Trigger `handle_new_user()` di database yang akan insert
    // seluruh field ini sekaligus ke tabel profiles (termasuk
    // status_akun default 'pending' untuk organizer / 'aktif'
    // untuk customer), jadi tidak perlu update terpisah setelah
    // signUp yang rawan gagal senyap kalau session belum aktif
    // (misal karena email confirmation).
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'nama_user': namaUser,
        'role': role,
        if (namaInstansi != null && namaInstansi.isNotEmpty)
          'nama_instansi': namaInstansi,
        if (nik != null && nik.isNotEmpty) 'nik': nik,
      },
    );

    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;

  Future<ProfileModel?> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final data = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (data == null) return null;
    return ProfileModel.fromJson(data);
  }

  Future<void> updateProfile({
    required String userId,
    String? namaUser,
    String? telpUser,
    String? namaInstansi,
    String? nik,
  }) async {
    final updates = <String, dynamic>{};
    if (namaUser != null) updates['nama_user'] = namaUser;
    if (telpUser != null) updates['telp_user'] = telpUser;
    if (namaInstansi != null) updates['nama_instansi'] = namaInstansi;
    if (nik != null) updates['nik'] = nik;

    if (updates.isNotEmpty) {
      await _client.from('profiles').update(updates).eq('id', userId);
    }
  }
}