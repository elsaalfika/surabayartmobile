class PameranModel {
  final String idPameran;
  final String namaPameran;
  final String? deskripsi;
  final String lokasi;
  final DateTime tanggalMulai;
  final DateTime tanggalSelesai;
  final String? posterUrl;
  final String statusVerifikasi; // pending | disetujui | ditolak
  final DateTime? tanggalVerifikasi;
  final String idPenyelenggara;
  final String? idAdmin;
  final DateTime? createdAt;

  // field tambahan hasil join (opsional, diisi manual di service)
  final String? namaPenyelenggara;

  PameranModel({
    required this.idPameran,
    required this.namaPameran,
    this.deskripsi,
    required this.lokasi,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    this.posterUrl,
    required this.statusVerifikasi,
    this.tanggalVerifikasi,
    required this.idPenyelenggara,
    this.idAdmin,
    this.createdAt,
    this.namaPenyelenggara,
  });

  factory PameranModel.fromJson(Map<String, dynamic> json) {
    return PameranModel(
      idPameran: json['id_pameran'] as String,
      namaPameran: json['nama_pameran'] as String? ?? '',
      deskripsi: json['deskripsi'] as String?,
      lokasi: json['lokasi'] as String? ?? '',
      tanggalMulai: DateTime.parse(json['tanggal_mulai'].toString()),
      tanggalSelesai: DateTime.parse(json['tanggal_selesai'].toString()),
      posterUrl: json['poster_url'] as String?,
      statusVerifikasi: json['status_verifikasi'] as String? ?? 'pending',
      tanggalVerifikasi: json['tanggal_verifikasi'] != null
          ? DateTime.tryParse(json['tanggal_verifikasi'].toString())
          : null,
      idPenyelenggara: json['id_penyelenggara'] as String,
      idAdmin: json['id_admin'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      namaPenyelenggara: json['profiles'] != null
          ? (json['profiles']['nama_instansi'] ?? json['profiles']['nama_user'])
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'nama_pameran': namaPameran,
      'deskripsi': deskripsi,
      'lokasi': lokasi,
      'tanggal_mulai': tanggalMulai.toIso8601String(),
      'tanggal_selesai': tanggalSelesai.toIso8601String(),
      'poster_url': posterUrl,
      'id_penyelenggara': idPenyelenggara,
    };
  }

  bool get isApproved => statusVerifikasi == 'disetujui';
  bool get isPending => statusVerifikasi == 'pending';
  bool get isRejected => statusVerifikasi == 'ditolak';
}