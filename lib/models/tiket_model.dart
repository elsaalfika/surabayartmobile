class TiketModel {
  final String idTiket;
  final String idPameran;
  final String namaTiket; // misal "Sesi 1 (09.00 - 12.00)"
  final double hargaTiket;
  final int kuota;
  final int tiketTerjual;
  final String statusTiket; // tersedia | habis | ditutup
  final DateTime? createdAt;

  TiketModel({
    required this.idTiket,
    required this.idPameran,
    required this.namaTiket,
    required this.hargaTiket,
    required this.kuota,
    this.tiketTerjual = 0,
    this.statusTiket = 'tersedia',
    this.createdAt,
  });

  factory TiketModel.fromJson(Map<String, dynamic> json) {
    return TiketModel(
      idTiket: json['id_tiket'] as String,
      idPameran: json['id_pameran'] as String,
      namaTiket: json['nama_tiket'] as String? ?? '',
      hargaTiket: (json['harga_tiket'] as num).toDouble(),
      kuota: json['kuota'] as int? ?? 0,
      tiketTerjual: json['tiket_terjual'] as int? ?? 0,
      statusTiket: json['status_tiket'] as String? ?? 'tersedia',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'id_pameran': idPameran,
      'nama_tiket': namaTiket,
      'harga_tiket': hargaTiket,
      'kuota': kuota,
    };
  }

  int get sisaTiket => kuota - tiketTerjual;
  bool get isTersedia => statusTiket == 'tersedia' && sisaTiket > 0;
}