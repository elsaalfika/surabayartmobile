import 'package:flutter/material.dart';
import '../models/tiket_model.dart';
import '../models/transaksi_model.dart';
import '../services/transaksi_service.dart';

/// Merepresentasikan satu item pesanan (1 tiket untuk 1 pengunjung)
class OrderItem {
  final TiketModel tiket;
  final String namaPengunjung;

  OrderItem({required this.tiket, required this.namaPengunjung});

  double get subtotal => tiket.hargaTiket;
}

class OrderProvider extends ChangeNotifier {
  final TransaksiService _service = TransaksiService();

  final List<OrderItem> cart = [];
  bool isLoading = false;
  String? errorMessage;
  TransaksiModel? lastTransaksi;

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

  Future<bool> konfirmasiPembayaran(String metodePembayaran) async {
    if (lastTransaksi == null) return false;
    isLoading = true;
    notifyListeners();
    try {
      await _service.konfirmasiPembayaran(
        idTransaksi: lastTransaksi!.idTransaksi,
        metodePembayaran: metodePembayaran,
      );
      clearCart();
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
}