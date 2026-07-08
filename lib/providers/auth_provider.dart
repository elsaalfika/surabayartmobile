import 'package:flutter/material.dart';
import '../models/profile_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus status = AuthStatus.unknown;
  ProfileModel? profile;
  String? errorMessage;
  bool isLoading = false;

  Future<void> checkCurrentSession() async {
    isLoading = true;
    notifyListeners();

    final user = _authService.currentUser;
    if (user != null) {
      profile = await _authService.getCurrentProfile();
      status = AuthStatus.authenticated;
    } else {
      status = AuthStatus.unauthenticated;
    }

    isLoading = false;
    notifyListeners();
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String namaUser,
    required String role,
    String? namaInstansi,
    String? nik,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final res = await _authService.signUp(
        email: email,
        password: password,
        namaUser: namaUser,
        role: role,
        namaInstansi: namaInstansi,
        nik: nik,
      );

      if (res.user != null) {
        profile = await _authService.getCurrentProfile();
        status = AuthStatus.authenticated;
        isLoading = false;
        notifyListeners();
        return true;
      }
      errorMessage = 'Registrasi gagal, silakan coba lagi.';
    } catch (e) {
      errorMessage = _mapError(e);
    }

    isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final res = await _authService.signIn(email: email, password: password);
      if (res.user != null) {
        profile = await _authService.getCurrentProfile();
        status = AuthStatus.authenticated;
        isLoading = false;
        notifyListeners();
        return true;
      }
      errorMessage = 'Email atau password salah.';
    } catch (e) {
      errorMessage = _mapError(e);
    }

    isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> signOut() async {
    await _authService.signOut();
    profile = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Dipakai user (customer/organizer) untuk mengedit profil miliknya sendiri.
  /// Berbeda dari AdminProvider.editProfile yang mengedit profil user lain.
  Future<bool> updateOwnProfile({
    String? namaUser,
    String? telpUser,
    String? namaInstansi,
    String? nik,
  }) async {
    final current = profile;
    if (current == null) return false;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _authService.updateProfile(
        userId: current.id,
        namaUser: namaUser,
        telpUser: telpUser,
        namaInstansi: namaInstansi,
        nik: nik,
      );
      profile = ProfileModel(
        id: current.id,
        namaUser: namaUser ?? current.namaUser,
        emailUser: current.emailUser,
        telpUser: telpUser ?? current.telpUser,
        role: current.role,
        namaInstansi: namaInstansi ?? current.namaInstansi,
        nik: nik ?? current.nik,
        statusAkun: current.statusAkun,
        tanggalDaftar: current.tanggalDaftar,
      );
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = _mapError(e);
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Wrapper sederhana untuk halaman My Profile (edit nama & telepon saja).
  Future<bool> updateProfile({String? namaUser, String? telpUser}) async {
    if (profile == null) return false;
    isLoading = true;
    notifyListeners();
    try {
      await _authService.updateProfile(
        userId: profile!.id,
        namaUser: namaUser,
        telpUser: telpUser,
      );
      profile = await _authService.getCurrentProfile();
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

  String _mapError(Object e) {
    final msg = e.toString();
    if (msg.contains('Invalid login credentials')) {
      return 'Email atau password salah.';
    }
    if (msg.contains('already registered')) {
      return 'Email sudah terdaftar.';
    }
    return 'Terjadi kesalahan: $msg';
  }
}