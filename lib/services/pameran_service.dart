import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pameran_model.dart';
import '../models/tiket_model.dart';

class PameranService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Ambil semua pameran yang sudah disetujui admin (untuk publik/customer)
  Future<List<PameranModel>> getApprovedPameran() async {
    final data = await _client
        .from('pameran')
        .select('*, profiles(nama_user, nama_instansi)')
        .eq('status_verifikasi', 'disetujui')
        .order('tanggal_mulai');

    return (data as List).map((e) => PameranModel.fromJson(e)).toList();
  }

  /// Ambil detail 1 pameran + daftar tiket/sesinya
  Future<PameranModel> getPameranById(String idPameran) async {
    final data = await _client
        .from('pameran')
        .select('*, profiles(nama_user, nama_instansi)')
        .eq('id_pameran', idPameran)
        .single();
    return PameranModel.fromJson(data);
  }

  Future<List<TiketModel>> getTiketByPameran(String idPameran) async {
    final data = await _client
        .from('tiket')
        .select()
        .eq('id_pameran', idPameran);
    return (data as List).map((e) => TiketModel.fromJson(e)).toList();
  }

  /// Pameran milik organizer yang sedang login
  Future<List<PameranModel>> getPameranByOrganizer(String idPenyelenggara) async {
    final data = await _client
        .from('pameran')
        .select()
        .eq('id_penyelenggara', idPenyelenggara)
        .order('created_at', ascending: false);
    return (data as List).map((e) => PameranModel.fromJson(e)).toList();
  }

  /// Semua pameran yang menunggu validasi (untuk admin)
  Future<List<PameranModel>> getPendingPameran() async {
    final data = await _client
        .from('pameran')
        .select('*, profiles(nama_user, nama_instansi)')
        .eq('status_verifikasi', 'pending')
        .order('created_at');
    return (data as List).map((e) => PameranModel.fromJson(e)).toList();
  }

  Future<PameranModel> createPameran({
    required String namaPameran,
    required String deskripsi,
    required String lokasi,
    required DateTime tanggalMulai,
    required DateTime tanggalSelesai,
    String? posterUrl,
    required String idPenyelenggara,
  }) async {
    final data = await _client
        .from('pameran')
        .insert({
          'nama_pameran': namaPameran,
          'deskripsi': deskripsi,
          'lokasi': lokasi,
          'tanggal_mulai': tanggalMulai.toIso8601String(),
          'tanggal_selesai': tanggalSelesai.toIso8601String(),
          'poster_url': posterUrl,
          'id_penyelenggara': idPenyelenggara,
        })
        .select()
        .single();
    return PameranModel.fromJson(data);
  }

  Future<void> updatePameran(String idPameran, Map<String, dynamic> updates) async {
    await _client.from('pameran').update(updates).eq('id_pameran', idPameran);
  }

  Future<void> deletePameran(String idPameran) async {
    await _client.from('pameran').delete().eq('id_pameran', idPameran);
  }

  /// Admin menyetujui atau menolak event
  Future<void> validasiPameran({
    required String idPameran,
    required bool disetujui,
    required String idAdmin,
  }) async {
    await _client.from('pameran').update({
      'status_verifikasi': disetujui ? 'disetujui' : 'ditolak',
      'tanggal_verifikasi': DateTime.now().toIso8601String(),
      'id_admin': idAdmin,
    }).eq('id_pameran', idPameran);
  }

  Future<TiketModel> createTiket({
    required String idPameran,
    required String namaTiket,
    required double hargaTiket,
    required int kuota,
  }) async {
    final data = await _client
        .from('tiket')
        .insert({
          'id_pameran': idPameran,
          'nama_tiket': namaTiket,
          'harga_tiket': hargaTiket,
          'kuota': kuota,
        })
        .select()
        .single();
    return TiketModel.fromJson(data);
  }

  Future<String> uploadPoster(String idPenyelenggara, List<int> fileBytes, String fileExt) async {
    final path = '$idPenyelenggara/${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    await _client.storage.from('poster-pameran').uploadBinary(path, fileBytes as dynamic);
    return _client.storage.from('poster-pameran').getPublicUrl(path);
  }
}