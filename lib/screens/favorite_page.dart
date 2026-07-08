import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../core/theme.dart';
import '../models/pameran_model.dart';
import '../providers/auth_provider.dart';
import '../providers/favorite_provider.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFavorites());
  }

  void _loadFavorites() {
    final idCustomer = context.read<AuthProvider>().profile?.id;
    if (idCustomer == null) return;
    context.read<FavoriteProvider>().loadFavorite(idCustomer);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 11) return 'Selamat Pagi';
    if (hour >= 11 && hour < 15) return 'Selamat Siang';
    if (hour >= 15 && hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  List<PameranModel> _filteredList(List<PameranModel> list) {
    if (_searchQuery.trim().isEmpty) return list;
    final query = _searchQuery.trim().toLowerCase();
    return list
        .where((p) => p.namaPameran.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final namaUser = context.watch<AuthProvider>().profile?.namaUser ?? 'Pengguna';
    final favoriteProvider = context.watch<FavoriteProvider>();
    final filteredList = _filteredList(favoriteProvider.favoriteList);

    return SafeArea(
      child: Column(
        children: [
          _buildHeaderBanner(namaUser),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _loadFavorites(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchBar(),
                    const SizedBox(height: 20),
                    const Text(
                      'FAVORITE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (favoriteProvider.isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (filteredList.isEmpty)
                      _buildEmptyState()
                    else
                      ...filteredList.map(
                        (pameran) => _FavoriteCard(
                          pameran: pameran,
                          onTap: () {
                            // TODO: arahkan ke halaman Detail Pergelaran
                          },
                          onFavoriteToggle: () {
                            final idCustomer =
                                context.read<AuthProvider>().profile?.id;
                            if (idCustomer == null) return;
                            context
                                .read<FavoriteProvider>()
                                .toggleFavorite(idCustomer, pameran);
                          },
                        ),
                      ),
                    const SizedBox(height: 100), // ruang untuk BottomNav yang mengambang
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBanner(String namaUser) {
    return SizedBox(
      height: 150,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/alun_alun_sby.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: AppColors.cardDarkAlt,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.45),
                ],
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Material(
              color: Colors.white.withOpacity(0.25),
              shape: const CircleBorder(),
              child: IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.chevron_left, color: Colors.white, size: 22),
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 14,
            right: 16,
            child: Text(
              '${_getGreeting()}, $namaUser!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(fontSize: 13, color: AppColors.textDark),
              decoration: const InputDecoration(
                hintText: 'search',
                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
            ),
          ),
          IconButton(
            onPressed: null,
            icon: const Icon(Icons.tune, color: AppColors.textMuted, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          const Icon(Icons.favorite_border, size: 40, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            _searchQuery.trim().isEmpty
                ? 'Belum ada pergelaran favorit'
                : 'Tidak ditemukan hasil untuk "$_searchQuery"',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final PameranModel pameran;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;

  const _FavoriteCard({
    required this.pameran,
    this.onTap,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMMM yyyy');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 70,
                height: 70,
                child: pameran.posterUrl != null
                    ? CachedNetworkImage(
                        imageUrl: pameran.posterUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: AppColors.border),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.border,
                          child: const Icon(Icons.image_not_supported_outlined, size: 20),
                        ),
                      )
                    : Container(
                        color: AppColors.border,
                        child: const Icon(Icons.image_outlined, size: 20),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pameran.namaPameran,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${dateFormat.format(pameran.tanggalMulai)} - ${dateFormat.format(pameran.tanggalSelesai)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          pameran.lokasi.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onFavoriteToggle,
              child: const Padding(
                padding: EdgeInsets.only(left: 8, top: 4),
                child: Icon(Icons.favorite, color: AppColors.danger, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}