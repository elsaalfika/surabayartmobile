class DetailTransaksiModel {
  final String idDetail;
  final String idTransaksi;
  final String idTiket;
  final String namaPengunjung;
  final int jumlah;
  final double subtotal;

  // opsional, hasil join untuk ditampilkan di riwayat
  final String? namaTiket;
  final String? namaPameran;

  DetailTransaksiModel({
    required this.idDetail,
    required this.idTransaksi,
    required this.idTiket,
    required this.namaPengunjung,
    required this.jumlah,
    required this.subtotal,
    this.namaTiket,
    this.namaPameran,
  });

  factory DetailTransaksiModel.fromJson(Map<String, dynamic> json) {
    return DetailTransaksiModel(
      idDetail: json['id_detail'] as String,
      idTransaksi: json['id_transaksi'] as String,
      idTiket: json['id_tiket'] as String,
      namaPengunjung: json['nama_pengunjung'] as String? ?? '',
      jumlah: json['jumlah'] as int? ?? 1,
      subtotal: (json['subtotal'] as num).toDouble(),
      namaTiket: json['tiket'] != null ? json['tiket']['nama_tiket'] : null,
      namaPameran: json['tiket'] != null && json['tiket']['pameran'] != null
          ? json['tiket']['pameran']['nama_pameran']
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
    };
  }
}

class TransaksiModel {
  final String idTransaksi;
  final String idCustomer;
  final DateTime tanggalTransaksi;
  final double totalHarga;
  final String? metodePembayaran; // qris | e_wallet | transfer_rekening
  final String statusPembayaran; // pending | berhasil | gagal | kadaluarsa

  final List<DetailTransaksiModel> details;

  TransaksiModel({
    required this.idTransaksi,
    required this.idCustomer,
    required this.tanggalTransaksi,
    required this.totalHarga,
    this.metodePembayaran,
    this.statusPembayaran = 'pending',
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