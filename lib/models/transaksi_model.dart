class DetailTransaksiModel {
  final String idDetail;
  final String idTransaksi;
  final String idTiket;
  final String namaPengunjung;
  final int jumlah;
  final double subtotal;
  final DateTime? tanggalKunjungan; // <-- baru

  // opsional, hasil join untuk ditampilkan di riwayat
  final String? namaTiket;
  final String? namaPameran;
  final String? idPameran;
  final String? lokasiPameran;
  final String? posterUrlPameran;
  final DateTime? tanggalMulaiPameran;
  final DateTime? tanggalSelesaiPameran;

  DetailTransaksiModel({
    required this.idDetail,
    required this.idTransaksi,
    required this.idTiket,
    required this.namaPengunjung,
    required this.jumlah,
    required this.subtotal,
    this.tanggalKunjungan,
    this.namaTiket,
    this.namaPameran,
    this.idPameran,
    this.lokasiPameran,
    this.posterUrlPameran,
    this.tanggalMulaiPameran,
    this.tanggalSelesaiPameran,
  });

  factory DetailTransaksiModel.fromJson(Map<String, dynamic> json) {
    final tiket = json['tiket'];
    final pameran = tiket != null ? tiket['pameran'] : null;

    return DetailTransaksiModel(
      idDetail: json['id_detail'] as String,
      idTransaksi: json['id_transaksi'] as String,
      idTiket: json['id_tiket'] as String,
      namaPengunjung: json['nama_pengunjung'] as String? ?? '',
      jumlah: json['jumlah'] as int? ?? 1,
      subtotal: (json['subtotal'] as num).toDouble(),
      tanggalKunjungan: json['tanggal_kunjungan'] != null
          ? DateTime.tryParse(json['tanggal_kunjungan'].toString())
          : null,
      namaTiket: tiket != null ? tiket['nama_tiket'] as String? : null,
      namaPameran: pameran != null ? pameran['nama_pameran'] as String? : null,
      idPameran: pameran != null ? pameran['id_pameran'] as String? : null,
      lokasiPameran: pameran != null ? pameran['lokasi'] as String? : null,
      posterUrlPameran: pameran != null ? pameran['poster_url'] as String? : null,
      tanggalMulaiPameran: pameran != null && pameran['tanggal_mulai'] != null
          ? DateTime.tryParse(pameran['tanggal_mulai'].toString())
          : null,
      tanggalSelesaiPameran: pameran != null && pameran['tanggal_selesai'] != null
          ? DateTime.tryParse(pameran['tanggal_selesai'].toString())
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'id_transaksi': idTransaksi,
      'id_tiket': idTiket,
      'nama_pengunjung': namaPengunjung,
      'jumlah': jumlah,
      'subtotal': subtotal,
      'tanggal_kunjungan': tanggalKunjungan?.toIso8601String().split('T').first,
    };
  }
}

class TransaksiModel {
  final String idTransaksi;
  final String idCustomer;
  final DateTime tanggalTransaksi;
  final double totalHarga;
  final String? metodePembayaran;
  final String statusPembayaran;
  final String? buktiBayarUrl;

  final List<DetailTransaksiModel> details;

  TransaksiModel({
    required this.idTransaksi,
    required this.idCustomer,
    required this.tanggalTransaksi,
    required this.totalHarga,
    this.metodePembayaran,
    this.statusPembayaran = 'pending',
    this.buktiBayarUrl,
    this.details = const [],
  });

  factory TransaksiModel.fromJson(Map<String, dynamic> json) {
    return TransaksiModel(
      idTransaksi: json['id_transaksi'] as String,
      idCustomer: json['id_customer'] as String,
      tanggalTransaksi: DateTime.parse(json['tanggal_transaksi'].toString()),
      totalHarga: (json['total_harga'] as num).toDouble(),
      metodePembayaran: json['metode_pembayaran'] as String?,
      statusPembayaran: json['status_pembayaran'] as String? ?? 'pending',
      buktiBayarUrl: json['bukti_bayar_url'] as String?,
      details: json['detail_transaksi'] != null
          ? (json['detail_transaksi'] as List)
              .map((e) => DetailTransaksiModel.fromJson(e))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'id_customer': idCustomer,
      'total_harga': totalHarga,
      'metode_pembayaran': metodePembayaran,
      'status_pembayaran': statusPembayaran,
    };
  }
}