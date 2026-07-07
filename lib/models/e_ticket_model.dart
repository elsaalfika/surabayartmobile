class ETicketModel {
  final String idTicket;
  final String idDetail;
  final String kodeQr;
  final bool statusCheckin;
  final DateTime? waktuCheckin;

  ETicketModel({
    required this.idTicket,
    required this.idDetail,
    required this.kodeQr,
    this.statusCheckin = false,
    this.waktuCheckin,
  });

  factory ETicketModel.fromJson(Map<String, dynamic> json) {
    return ETicketModel(
      idTicket: json['id_ticket'] as String,
      idDetail: json['id_detail'] as String,
      kodeQr: json['kode_qr'] as String? ?? '',
      statusCheckin: json['status_checkin'] as bool? ?? false,
      waktuCheckin: json['waktu_checkin'] != null
          ? DateTime.tryParse(json['waktu_checkin'].toString())
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'id_detail': idDetail,
      'kode_qr': kodeQr,
    };
  }
}