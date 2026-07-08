import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/profile_model.dart';
import '../models/pameran_model.dart';
import '../services/admin_service.dart';
import '../services/pameran_service.dart';

class AdminProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();
  final PameranService _pameranService = PameranService();

  bool isLoading = false;
  String? errorMessage;

  List<PameranModel> pendingEvents = [];
  List<PameranModel> allEvents = [];
  List<ProfileModel> customers = [];
  List<ProfileModel> organizers = [];

  int totalPengguna = 0;
  int totalOrganizer = 0;
  int eventAktifCount = 0;
  int menungguValidasiCount = 0;

  /// Gabungan customer + organizer untuk tab "User".
  /// Tiap item tetap punya `role` yang bisa dipakai untuk kasih badge
  /// Customer/Organizer di UI.
  List<ProfileModel> get allUsers => [...customers, ...organizers];

  void _logError(String context, Object e) {
    errorMessage = e.toString();
    // ignore: avoid_print
    if (kDebugMode) print('[AdminProvider] Error in $context: $e');
  }

  Future<void> loadOverview() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _adminService.countByRole('customer'),
        _adminService.countByRole('organizer'),
        _pameranService.getApprovedPameran(),
        _pameranService.getPendingPameran(),
      ]);
      totalPengguna = results[0] as int;
      totalOrganizer = results[1] as int;
      eventAktifCount = (results[2] as List).length;
      pendingEvents = results[3] as List<PameranModel>;
      menungguValidasiCount = pendingEvents.length;
    } catch (e) {
      _logError('loadOverview', e);
    }
    isLoading = false;
    notifyListeners();
  }

  /// Ambil semua event apapun statusnya, untuk tab "Event".
  Future<void> loadAllEvents() async {
    try {
      allEvents = await _pameranService.getAllPameran();
      notifyListeners();
    } catch (e) {
      _logError('loadAllEvents', e);
      notifyListeners();
    }
  }

  Future<void> loadCustomers() async {
    try {
      customers = await _adminService.getUsersByRole('customer');
      notifyListeners();
    } catch (e) {
      _logError('loadCustomers', e);
      notifyListeners();
    }
  }

  Future<void> loadOrganizers() async {
    try {
      organizers = await _adminService.getUsersByRole('organizer');
      notifyListeners();
    } catch (e) {
      _logError('loadOrganizers', e);
      notifyListeners();
    }
  }

  Future<bool> approveEvent(String idPameran, String idAdmin) async {
    try {
      await _pameranService.validasiPameran(
        idPameran: idPameran,
        disetujui: true,
        idAdmin: idAdmin,
      );
      pendingEvents.removeWhere((e) => e.idPameran == idPameran);
      menungguValidasiCount = pendingEvents.length;
      eventAktifCount += 1;
      // Sinkronkan juga status di allEvents kalau sudah pernah di-load
      final idx = allEvents.indexWhere((e) => e.idPameran == idPameran);
      if (idx != -1) {
        await loadAllEvents();
      }
      notifyListeners();
      return true;
    } catch (e) {
      _logError('approveEvent', e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectEvent(String idPameran, String idAdmin) async {
    try {
      await _pameranService.validasiPameran(
        idPameran: idPameran,
        disetujui: false,
        idAdmin: idAdmin,
      );
      pendingEvents.removeWhere((e) => e.idPameran == idPameran);
      menungguValidasiCount = pendingEvents.length;
      final idx = allEvents.indexWhere((e) => e.idPameran == idPameran);
      if (idx != -1) {
        await loadAllEvents();
      }
      notifyListeners();
      return true;
    } catch (e) {
      _logError('rejectEvent', e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleBlockUser(ProfileModel user, {required bool isOrganizer}) async {
    final newStatus = user.statusAkun == 'aktif' ? 'nonaktif' : 'aktif';
    try {
      await _adminService.toggleStatusAkun(user.id, newStatus);
      final list = isOrganizer ? organizers : customers;
      final idx = list.indexWhere((u) => u.id == user.id);
      if (idx != -1) {
        list[idx] = ProfileModel(
          id: user.id,
          namaUser: user.namaUser,
          emailUser: user.emailUser,
          telpUser: user.telpUser,
          role: user.role,
          namaInstansi: user.namaInstansi,
          nik: user.nik,
          statusAkun: newStatus,
          tanggalDaftar: user.tanggalDaftar,
        );
      }
      notifyListeners();
      return true;
    } catch (e) {
      _logError('toggleBlockUser', e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> editProfile({
    required ProfileModel user,
    required bool isOrganizer,
    required String namaUser,
    String? namaInstansi,
    String? nik,
    String? telpUser,
  }) async {
    try {
      await _adminService.updateProfileByAdmin(
        userId: user.id,
        namaUser: namaUser,
        namaInstansi: namaInstansi,
        nik: nik,
        telpUser: telpUser,
      );
      final list = isOrganizer ? organizers : customers;
      final idx = list.indexWhere((u) => u.id == user.id);
      if (idx != -1) {
        list[idx] = ProfileModel(
          id: user.id,
          namaUser: namaUser,
          emailUser: user.emailUser,
          telpUser: telpUser ?? user.telpUser,
          role: user.role,
          namaInstansi: namaInstansi ?? user.namaInstansi,
          nik: nik ?? user.nik,
          statusAkun: user.statusAkun,
          tanggalDaftar: user.tanggalDaftar,
        );
      }
      notifyListeners();
      return true;
    } catch (e) {
      _logError('editProfile', e);
      notifyListeners();
      return false;
    }
  }
}