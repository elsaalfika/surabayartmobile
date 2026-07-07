import 'package:flutter/material.dart';
import '../models/pameran_model.dart';
import '../models/tiket_model.dart';
import '../services/pameran_service.dart';

class PameranProvider extends ChangeNotifier {
  final PameranService _service = PameranService();

  List<PameranModel> pameranList = [];
  List<PameranModel> pendingList = []; // untuk admin
  List<PameranModel> myEventList = []; // untuk organizer
  Map<String, List<TiketModel>> tiketPerPameran = {};

  bool isLoading = false;
  String? errorMessage;

  Future<void> loadApprovedPameran() async {
    isLoading = true;
    notifyListeners();
    try {
      pameranList = await _service.getApprovedPameran();
    } catch (e) {
      errorMessage = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadPendingPameran() async {
    isLoading = true;
    notifyListeners();
    try {
      pendingList = await _service.getPendingPameran();
    } catch (e) {
      errorMessage = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadMyEvent(String idPenyelenggara) async {
    isLoading = true;
    notifyListeners();
    try {
      myEventList = await _service.getPameranByOrganizer(idPenyelenggara);
    } catch (e) {
      errorMessage = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<List<TiketModel>> loadTiket(String idPameran) async {
    final list = await _service.getTiketByPameran(idPameran);
    tiketPerPameran[idPameran] = list;
    notifyListeners();
    return list;
  }

  Future<bool> createPameran({
    required String namaPameran,
    required String deskripsi,
    required String lokasi,
    required DateTime tanggalMulai,
    required DateTime tanggalSelesai,
    String? posterUrl,
    required String idPenyelenggara,
    required List<Map<String, dynamic>> sesiTiket, // [{nama, harga, kuota}]
  }) async {
    isLoading = true;
    notifyListeners();
    try {
      final pameran = await _service.createPameran(
        namaPameran: namaPameran,
        deskripsi: deskripsi,
        lokasi: lokasi,
        tanggalMulai: tanggalMulai,
        tanggalSelesai: tanggalSelesai,
        posterUrl: posterUrl,
        idPenyelenggara: idPenyelenggara,
      );

      for (final sesi in sesiTiket) {
        await _service.createTiket(
          idPameran: pameran.idPameran,
          namaTiket: sesi['nama'] as String,
          hargaTiket: (sesi['harga'] as num).toDouble(),
          kuota: sesi['kuota'] as int,
        );
      }

      await loadMyEvent(idPenyelenggara);
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

  Future<void> deletePameran(String idPameran, String idPenyelenggara) async {
    await _service.deletePameran(idPameran);
    await loadMyEvent(idPenyelenggara);
  }

  Future<void> validasiPameran(String idPameran, bool disetujui, String idAdmin) async {
    await _service.validasiPameran(
      idPameran: idPameran,
      disetujui: disetujui,
      idAdmin: idAdmin,
    );
    await loadPendingPameran();
  }
}