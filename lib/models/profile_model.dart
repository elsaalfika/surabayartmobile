class ProfileModel {
  final String id;
  final String namaUser;
  final String emailUser;
  final String? telpUser;
  final String role; // 'customer' | 'organizer' | 'admin'
  final String? namaInstansi;
  final String? nik;
  final String? statusAkun;
  final DateTime? tanggalDaftar;

  ProfileModel({
    required this.id,
    required this.namaUser,
    required this.emailUser,
    this.telpUser,
    required this.role,
    this.namaInstansi,
    this.nik,
    this.statusAkun,
    this.tanggalDaftar,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      namaUser: json['nama_user'] as String? ?? '',
      emailUser: json['email_user'] as String? ?? '',
      telpUser: json['telp_user'] as String?,
      role: json['role'] as String? ?? 'customer',
      namaInstansi: json['nama_instansi'] as String?,
      nik: json['nik'] as String?,
      statusAkun: json['status_akun'] as String?,
      tanggalDaftar: json['tanggal_daftar'] != null
          ? DateTime.tryParse(json['tanggal_daftar'].toString())
          : null,
    );
  }

  bool get isCustomer => role == 'customer';
  bool get isOrganizer => role == 'organizer';
  bool get isAdmin => role == 'admin';
}