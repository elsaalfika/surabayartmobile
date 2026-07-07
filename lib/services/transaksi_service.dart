import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaksi_model.dart';
import '../models/e_ticket_model.dart';

class TransaksiService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Buat transaksi baru beserta detail_transaksi (item tiket yang dipesan)
  /// [items] contoh: [{ 'id_tiket': ..., 'nama_pengunjung': ..., 'jumlah': 1, 'subtotal': 55000 }]
  Future<TransaksiModel> createTransaksi({
    required String idCustomer,
    required double totalHarga,
    required List<Map<String, dynamic>> items,
  }) async {
    // 1. Buat transaksi induk
    final transaksiData = await _client
        .from('transaksi')
        .insert({
          'id_customer': idCustomer,
          'total_harga': totalHarga,
          'status_pembayaran': 'pending',
        })
        .select()
        .single();

    final idTransaksi = transaksiData['id_transaksi'] as String;

    // 2. Insert semua detail transaksi
    final detailRows = items
        .map((item) => {
              'id_transaksi': idTransaksi,
              'id_tiket': item['id_tiket'],
              'nama_pengunjung': item['nama_pengunjung'],
              'jumlah': item['jumlah'],
              'subtotal': item['subtotal'],
            })
        .toList();

    await _client.from('detail_transaksi').insert(detailRows);

    return TransaksiModel.fromJson(transaksiData);
  }

  /// Simulasi konfirmasi pembayaran (QRIS/e-wallet/transfer).
  /// Di real case ini akan dipanggil dari webhook payment gateway.
  Future<void> konfirmasiPembayaran({
    required String idTransaksi,
    required String metodePembayaran,
  }) async {
    await _client.from('transaksi').update({
      'metode_pembayaran': metodePembayaran,
      'status_pembayaran': 'berhasil',
    }).eq('id_transaksi', idTransaksi);

    // Generate e-ticket untuk setiap detail_transaksi pada transaksi ini
    final details = await _client
        .from('detail_transaksi')
        .select('id_detail')
        .eq('id_transaksi', idTransaksi);

    for (final detail in details) {
      final kodeQr = _generateKodeQr();
      await _client.from('e_ticket').insert({
        'id_detail': detail['id_detail'],
        'kode_qr': kodeQr,
      });
    }

    // Update jumlah tiket terjual di tabel tiket
    final detailWithTiket = await _client
        .from('detail_transaksi')
        .select('id_tiket, jumlah')
        .eq('id_transaksi', idTransaksi);

    for (final row in detailWithTiket) {
      await _client.rpc('increment_tiket_terjual', params: {
        'p_id_tiket': row['id_tiket'],
        'p_jumlah': row['jumlah'],
      });
    }
  }

  String _generateKodeQr() {
    final rand = Random.secure();
    return List.generate(12, (_) => rand.nextInt(10)).join();
  }

  /// Riwayat transaksi milik customer yang sedang login
  Future<List<TransaksiModel>> getRiwayatTransaksi(String idCustomer) async {
    final data = await _client
        .from('transaksi')
        .select('*, detail_transaksi(*, tiket(nama_tiket, pameran(nama_pameran)))')
        .eq('id_customer', idCustomer)
        .order('tanggal_transaksi', ascending: false);

    return (data as List).map((e) => TransaksiModel.fromJson(e)).toList();
  }

  Future<List<ETicketModel>> getETicketByTransaksi(String idTransaksi) async {
    final data = await _client
        .from('e_ticket')
        .select('*, detail_transaksi!inner(id_transaksi)')
        .eq('detail_transaksi.id_transaksi', idTransaksi);

    return (data as List).map((e) => ETicketModel.fromJson(e)).toList();
  }
}