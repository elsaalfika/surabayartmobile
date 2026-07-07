import 'package:flutter/material.dart';
import '../models/pameran_model.dart';
import '../services/favorite_service.dart';

class FavoriteProvider extends ChangeNotifier {
  final FavoriteService _service = FavoriteService();

  List<PameranModel> favoriteList = [];
  bool isLoading = false;

  Future<void> loadFavorite(String idCustomer) async {
    isLoading = true;
    notifyListeners();
    favoriteList = await _service.getFavoritePameran(idCustomer);
    isLoading = false;
    notifyListeners();
  }

  bool isFavorited(String idPameran) {
    return favoriteList.any((p) => p.idPameran == idPameran);
  }

  Future<void> toggleFavorite(String idCustomer, PameranModel pameran) async {
    final wasFavorite = isFavorited(pameran.idPameran);

    // Optimistic update
    if (wasFavorite) {
      favoriteList.removeWhere((p) => p.idPameran == pameran.idPameran);
    } else {
      favoriteList.add(pameran);
    }
    notifyListeners();

    try {
      await _service.toggleFavorite(idCustomer, pameran.idPameran);
    } catch (e) {
      // rollback kalau gagal
      if (wasFavorite) {
        favoriteList.add(pameran);
      } else {
        favoriteList.removeWhere((p) => p.idPameran == pameran.idPameran);
      }
      notifyListeners();
    }
  }
}