class TicketViewModel {
  final String idTicket;
  final String kodeQr;
  final bool statusCheckin;
  final DateTime? waktuCheckin;

  final String namaPengunjung;
  final String? namaTiket;

  final String idPameran;
  final String namaPameran;
  final String lokasi;
  final String? posterUrl;
  final DateTime tanggalMulai;
  final DateTime tanggalSelesai;
  final DateTime? tanggalKunjungan; // <-- baru, tanggal yang dipilih customer

  TicketViewModel({
    required this.idTicket,
    required this.kodeQr,
    required this.statusCheckin,
    this.waktuCheckin,
    required this.namaPengunjung,
    this.namaTiket,
    required this.idPameran,
    required this.namaPameran,
    required this.lokasi,
    this.posterUrl,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    this.tanggalKunjungan,
  });
}