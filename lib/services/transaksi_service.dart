import 'dart:math';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaksi_model.dart';
import '../models/e_ticket_model.dart';
import '../models/ticket_view_model.dart';

class TransaksiService {
  final SupabaseClient _client = Supabase.instance.client;

  static const _buktiBayarBucket = 'bukti-pembayaran';

  /// Buat transaksi baru beserta detail_transaksi (item tiket yang dipesan)
  Future<TransaksiModel> createTransaksi({
    required String idCustomer,
    required double totalHarga,
    required List<Map<String, dynamic>> items,
  }) async {
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

    final detailRows = items
        .map((item) => {
              'id_transaksi': idTransaksi,
              'id_tiket': item['id_tiket'],
              'nama_pengunjung': item['nama_pengunjung'],
              'jumlah': item['jumlah'],
              'subtotal': item['subtotal'],
              'tanggal_kunjungan': item['tanggal_kunjungan'], // <-- baru
            })
        .toList();

    await _client.from('detail_transaksi').insert(detailRows);

    return TransaksiModel.fromJson(transaksiData);
  }

  /// Upload bukti bayar ke Supabase Storage, mengembalikan public URL-nya.
  Future<String> uploadBuktiBayar({
    required String idTransaksi,
    required Uint8List bytes,
    required String fileExt, // contoh: 'jpg', 'png'
  }) async {
    final path = '$idTransaksi/bukti_bayar.$fileExt';

    await _client.storage.from(_buktiBayarBucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );

    return _client.storage.from(_buktiBayarBucket).getPublicUrl(path);
  }

  /// Konfirmasi pembayaran: simpan bukti bayar, ubah status, generate e-ticket.
  Future<void> konfirmasiPembayaran({
    required String idTransaksi,
    required String metodePembayaran,
    required String buktiBayarUrl,
  }) async {
    await _client.from('transaksi').update({
      'metode_pembayaran': metodePembayaran,
      'status_pembayaran': 'berhasil',
      'bukti_bayar_url': buktiBayarUrl,
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
        .select(
            '*, detail_transaksi(*, tiket(nama_tiket, pameran(*)))')
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

  /// Semua tiket (e_ticket) milik customer yang pembayarannya sudah berhasil.
  /// Dipakai di halaman My Ticket.
  Future<List<TicketViewModel>> getMyTickets(String idCustomer) async {
    final transaksiList = await getRiwayatTransaksi(idCustomer);
    final berhasil = transaksiList.where((t) => t.statusPembayaran == 'berhasil');

    final idDetailList = berhasil
        .expand((t) => t.details)
        .map((d) => d.idDetail)
        .toList();

    if (idDetailList.isEmpty) return [];

    final eTicketData = await _client
        .from('e_ticket')
        .select()
        .inFilter('id_detail', idDetailList);

    final eTicketByDetail = {
      for (final row in eTicketData) row['id_detail'] as String: row,
    };

    final result = <TicketViewModel>[];
    for (final transaksi in berhasil) {
      for (final detail in transaksi.details) {
        final eTicket = eTicketByDetail[detail.idDetail];
        if (eTicket == null) continue;
        if (detail.idPameran == null) continue;

        result.add(TicketViewModel(
          idTicket: eTicket['id_ticket'] as String,
          kodeQr: eTicket['kode_qr'] as String? ?? '',
          statusCheckin: eTicket['status_checkin'] as bool? ?? false,
          waktuCheckin: eTicket['waktu_checkin'] != null
              ? DateTime.tryParse(eTicket['waktu_checkin'].toString())
              : null,
          namaPengunjung: detail.namaPengunjung,
          namaTiket: detail.namaTiket,
          idPameran: detail.idPameran!,
          namaPameran: detail.namaPameran ?? '-',
          lokasi: detail.lokasiPameran ?? '-',
          posterUrl: detail.posterUrlPameran,
          tanggalMulai: detail.tanggalMulaiPameran ?? transaksi.tanggalTransaksi,
          tanggalSelesai: detail.tanggalSelesaiPameran ?? transaksi.tanggalTransaksi,
          tanggalKunjungan: detail.tanggalKunjungan, // <-- baru
        ));
      }
    }

    result.sort((a, b) => b.tanggalMulai.compareTo(a.tanggalMulai));
    return result;
  }
}