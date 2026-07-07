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
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'nama_user': namaUser,
        'role': role,
      },
    );

    if (response.user != null && role == 'organizer') {
      await _client.from('profiles').update({
        'nama_instansi': namaInstansi,
        'nik': nik,
        'status_akun': 'pending',
      }).eq('id', response.user!.id);
    }

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
  }) async {
    final updates = <String, dynamic>{};
    if (namaUser != null) updates['nama_user'] = namaUser;
    if (telpUser != null) updates['telp_user'] = telpUser;

    if (updates.isNotEmpty) {
      await _client.from('profiles').update(updates).eq('id', userId);
    }
  }
}