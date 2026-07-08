import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/tiket_model.dart';
import '../models/pameran_model.dart';
import '../models/transaksi_model.dart';
import '../models/ticket_view_model.dart';
import '../services/transaksi_service.dart';

class OrderItem {
  final TiketModel tiket;
  final PameranModel pameran;
  final String namaPengunjung;
  final DateTime tanggalKunjungan; // <-- baru

  OrderItem({
    required this.tiket,
    required this.pameran,
    required this.namaPengunjung,
    required this.tanggalKunjungan,
  });

  double get subtotal => tiket.hargaTiket;
}

class OrderProvider extends ChangeNotifier {
  final TransaksiService _service = TransaksiService();
  final ImagePicker _picker = ImagePicker();

  final List<OrderItem> cart = [];
  bool isLoading = false;
  String? errorMessage;
  TransaksiModel? lastTransaksi;

  // --- Bukti bayar ---
  XFile? buktiBayarFile;
  Uint8List? buktiBayarPreviewBytes;

  double get totalHarga => cart.fold(0, (sum, item) => sum + item.subtotal);

  void addItem(OrderItem item) {
    cart.add(item);
    notifyListeners();
  }

  void removeItem(int index) {
    cart.removeAt(index);
    notifyListeners();
  }

  void clearCart() {
    cart.clear();
    notifyListeners();
  }

  Future<void> pickBuktiBayar() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file == null) return;
    buktiBayarFile = file;
    buktiBayarPreviewBytes = await file.readAsBytes();
    notifyListeners();
  }

  void clearBuktiBayar() {
    buktiBayarFile = null;
    buktiBayarPreviewBytes = null;
    notifyListeners();
  }

  Future<bool> checkout(String idCustomer) async {
    if (cart.isEmpty) return false;
    isLoading = true;
    notifyListeners();

    try {
      final items = cart
          .map((item) => {
                'id_tiket': item.tiket.idTiket,
                'nama_pengunjung': item.namaPengunjung,
                'jumlah': 1,
                'subtotal': item.subtotal,
                'tanggal_kunjungan':
                    item.tanggalKunjungan.toIso8601String().split('T').first, // <-- baru
              })
          .toList();

      lastTransaksi = await _service.createTransaksi(
        idCustomer: idCustomer,
        totalHarga: totalHarga,
        items: items,
      );

      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Upload bukti bayar yang sudah dipilih, lalu konfirmasi pembayaran.
  Future<bool> konfirmasiPembayaran(String metodePembayaran) async {
    if (lastTransaksi == null) return false;
    if (buktiBayarFile == null || buktiBayarPreviewBytes == null) {
      errorMessage = 'Silakan upload bukti pembayaran terlebih dahulu.';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final fileExt = buktiBayarFile!.name.split('.').last;
      final buktiUrl = await _service.uploadBuktiBayar(
        idTransaksi: lastTransaksi!.idTransaksi,
        bytes: buktiBayarPreviewBytes!,
        fileExt: fileExt.isNotEmpty ? fileExt : 'jpg',
      );

      await _service.konfirmasiPembayaran(
        idTransaksi: lastTransaksi!.idTransaksi,
        metodePembayaran: metodePembayaran,
        buktiBayarUrl: buktiUrl,
      );

      clearCart();
      clearBuktiBayar();
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<List<TransaksiModel>> loadRiwayat(String idCustomer) async {
    return await _service.getRiwayatTransaksi(idCustomer);
  }

  // --- My Ticket ---
  List<TicketViewModel> myTickets = [];
  bool isLoadingTickets = false;

  Future<void> loadMyTickets(String idCustomer) async {
    isLoadingTickets = true;
    notifyListeners();
    try {
      myTickets = await _service.getMyTickets(idCustomer);
    } catch (e) {
      errorMessage = e.toString();
    }
    isLoadingTickets = false;
    notifyListeners();
  }
}