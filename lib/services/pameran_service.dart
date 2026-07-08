import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pameran_model.dart';
import '../models/tiket_model.dart';

class PameranService {
  final SupabaseClient _client = Supabase.instance.client;

  // Catatan: tabel `pameran` punya 2 foreign key ke `profiles`
  // (id_penyelenggara dan id_admin), jadi join implisit `profiles(...)`
  // ambigu bagi PostgREST. Harus pakai hint nama constraint eksplisit:
  // profiles!pameran_id_penyelenggara_fkey(...)

  Future<List<PameranModel>> getApprovedPameran() async {
    final data = await _client
        .from('pameran')
        .select('*, profiles!pameran_id_penyelenggara_fkey(nama_user, nama_instansi)')
        .eq('status_verifikasi', 'disetujui')
        .order('tanggal_mulai');
    return (data as List).map((e) => PameranModel.fromJson(e)).toList();
  }

  Future<PameranModel> getPameranById(String idPameran) async {
    final data = await _client
        .from('pameran')
        .select('*, profiles!pameran_id_penyelenggara_fkey(nama_user, nama_instansi)')
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

  Future<List<PameranModel>> getPameranByOrganizer(String idPenyelenggara) async {
    final data = await _client
        .from('pameran')
        .select()
        .eq('id_penyelenggara', idPenyelenggara)
        .order('created_at', ascending: false);
    return (data as List).map((e) => PameranModel.fromJson(e)).toList();
  }

  Future<List<PameranModel>> getPendingPameran() async {
    final data = await _client
        .from('pameran')
        .select('*, profiles!pameran_id_penyelenggara_fkey(nama_user, nama_instansi)')
        .eq('status_verifikasi', 'pending')
        .order('created_at');
    return (data as List).map((e) => PameranModel.fromJson(e)).toList();
  }

  /// Ambil SEMUA event apapun statusnya (pending, disetujui, ditolak)
  /// Dipakai untuk tab "Event" di admin dashboard.
  Future<List<PameranModel>> getAllPameran() async {
    final data = await _client
        .from('pameran')
        .select('*, profiles!pameran_id_penyelenggara_fkey(nama_user, nama_instansi)')
        .order('created_at', ascending: false);
    return (data as List).map((e) => PameranModel.fromJson(e)).toList();
  }

  Future<PameranModel> createPameran({
    required String namaPameran,
    required String deskripsi,
    required String lokasi,
    required DateTime tanggalMulai,
    required DateTime tanggalSelesai,
    String? waktuMulai,
    String? waktuSelesai,
    String? posterUrl,
    String? qrPembayaranUrl,
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
          'waktu_mulai': waktuMulai,
          'waktu_selesai': waktuSelesai,
          'poster_url': posterUrl,
          'qr_pembayaran_url': qrPembayaranUrl,
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

  /// Upload poster event. fileExt harus salah satu dari: jpg, jpeg, png
  Future<String> uploadPoster(
    String idPenyelenggara,
    Uint8List fileBytes,
    String fileExt,
  ) async {
    final path = '$idPenyelenggara/${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    await _client.storage.from('poster-pameran').uploadBinary(path, fileBytes);
    return _client.storage.from('poster-pameran').getPublicUrl(path);
  }

  /// Upload QR code pembayaran organizer. fileExt: jpg, jpeg, png
  Future<String> uploadQrPembayaran(
    String idPenyelenggara,
    Uint8List fileBytes,
    String fileExt,
  ) async {
    final path = '$idPenyelenggara/${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    await _client.storage.from('qr-pembayaran').uploadBinary(path, fileBytes);
    return _client.storage.from('qr-pembayaran').getPublicUrl(path);
  }
}