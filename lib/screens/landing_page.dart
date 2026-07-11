import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/pameran_model.dart';
import '../providers/auth_provider.dart';
import '../providers/favorite_provider.dart';
import '../providers/pameran_provider.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/event_card.dart';
import 'favorite_page.dart';
import 'profile_page.dart';
import 'ticket_list_page.dart';
import 'ticket_order_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    final customerId = auth.profile?.id;

    await context.read<PameranProvider>().loadApprovedPameran();
    if (customerId != null) {
      await context.read<FavoriteProvider>().loadFavorite(customerId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          IndexedStack(
            index: _navIndex,
            children: [
              _HomeTab(onRefresh: _loadData),
              const FavoritePage(),
              const TicketListPage(),
              const ProfilePage(),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomNav(
              currentIndex: _navIndex,
              onTap: (i) => setState(() => _navIndex = i),
            ),
          ),
        ],
      ),
    );
  }
}

/// ================= HOME TAB =================

enum SortMode { terbaru, termurah, termahal, namaAz }

class _HomeTab extends StatefulWidget {
  final Future<void> Function() onRefresh;
  const _HomeTab({required this.onRefresh});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final _searchController = TextEditingController();
  String _query = '';
  SortMode _sortMode = SortMode.terbaru;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  bool _isSameOrAfter(DateTime a, DateTime b) =>
      !a.isBefore(DateTime(b.year, b.month, b.day));
  bool _isSameOrBefore(DateTime a, DateTime b) =>
      !a.isAfter(DateTime(b.year, b.month, b.day));

  List<PameranModel> _applySort(List<PameranModel> items, {double Function(PameranModel)? hargaGetter}) {
    final sorted = [...items];
    switch (_sortMode) {
      case SortMode.terbaru:
        sorted.sort((a, b) => (b.createdAt ?? b.tanggalMulai)
            .compareTo(a.createdAt ?? a.tanggalMulai));
        break;
      case SortMode.namaAz:
        sorted.sort((a, b) => a.namaPameran.toLowerCase().compareTo(b.namaPameran.toLowerCase()));
        break;
      case SortMode.termurah:
      case SortMode.termahal:
        // Harga ada di tabel tiket (terpisah), jadi sort harga di-skip di level ini
        // kalau nanti ada field harga langsung di PameranModel, tinggal aktifkan.
        break;
    }
    return sorted;
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Urutkan',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _sortOption(ctx, 'Terbaru', SortMode.terbaru),
                _sortOption(ctx, 'Nama A-Z', SortMode.namaAz),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sortOption(BuildContext ctx, String label, SortMode mode) {
    final selected = _sortMode == mode;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(fontSize: 13)),
      trailing: selected ? const Icon(Icons.check, size: 18) : null,
      onTap: () {
        setState(() => _sortMode = mode);
        Navigator.pop(ctx);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final pameranProvider = context.watch<PameranProvider>();
    final favoriteProvider = context.watch<FavoriteProvider>();

    final today = DateTime.now();
    final all = pameranProvider.pameranList;

    var nowShowing = all.where((p) {
      final match = p.namaPameran.toLowerCase().contains(_query);
      final started = _isSameOrAfter(today, p.tanggalMulai);
      final notEnded = _isSameOrBefore(today, p.tanggalSelesai);
      return match && started && notEnded;
    }).toList();
    nowShowing = _applySort(nowShowing);

    var upcoming = all.where((p) {
      final match = p.namaPameran.toLowerCase().contains(_query);
      final notStartedYet = today.isBefore(
        DateTime(p.tanggalMulai.year, p.tanggalMulai.month, p.tanggalMulai.day),
      );
      return match && notStartedYet;
    }).toList();
    upcoming = _applySort(upcoming);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildBanner(auth)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchBar(),
                    const SizedBox(height: 20),
                    const Text('NOW SHOWING',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    _buildHorizontalList(
                      items: nowShowing,
                      emptyText: 'Belum ada pergelaran yang sedang berlangsung.',
                      isReservable: true,
                      favoriteProvider: favoriteProvider,
                      auth: auth,
                    ),
                    const SizedBox(height: 24),
                    const Text('UPCOMING SHOW',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    _buildHorizontalList(
                      items: upcoming,
                      emptyText: 'Belum ada pergelaran mendatang.',
                      isReservable: false,
                      favoriteProvider: favoriteProvider,
                      auth: auth,
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 90)),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner(AuthProvider auth) {
    return Stack(
      children: [
        SizedBox(
          height: 150,
          width: double.infinity,
          child: Image.asset('assets/images/alun_alun_sby.png', fit: BoxFit.cover),
        ),
        Container(
          height: 150,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withOpacity(0.05), Colors.black.withOpacity(0.55)],
            ),
          ),
        ),
        Positioned(
          left: 16,
          top: 12,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
          ),
        ),
        Positioned(
          left: 16,
          bottom: 14,
          right: 16,
          child: Text(
            '${_greeting()}, ${auth.profile?.namaUser ?? 'Pengguna'}!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18, color: Colors.black45),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'search',
                hintStyle: TextStyle(fontSize: 13, color: Colors.black38),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          InkWell(
            onTap: _openFilterSheet,
            child: const Icon(Icons.tune, size: 18, color: Colors.black45),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalList({
    required List<PameranModel> items,
    required String emptyText,
    required bool isReservable,
    required FavoriteProvider favoriteProvider,
    required AuthProvider auth,
  }) {
    if (items.isEmpty) {
      return SizedBox(
        height: 60,
        child: Center(
          child: Text(emptyText,
              style: const TextStyle(fontSize: 12, color: Colors.black38)),
        ),
      );
    }

    return SizedBox(
      height: 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final pameran = items[index];
          return EventCard(
            pameran: pameran,
            showReserveLabel: isReservable,
            isFavorite: favoriteProvider.isFavorited(pameran.idPameran),
            onFavoriteToggle: () {
              final customerId = auth.profile?.id;
              if (customerId != null) {
                favoriteProvider.toggleFavorite(customerId, pameran);
              }
            },
            onTap: isReservable ? () => _showEventPreview(context, pameran) : null,
          );
        },
      ),
    );
  }

  void _showEventPreview(BuildContext context, PameranModel pameran) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.zero,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Hero(
                    tag: 'poster_${pameran.idPameran}',
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: pameran.posterUrl != null
                          ? Image.network(pameran.posterUrl!, fit: BoxFit.cover)
                          : Container(color: AppColors.border),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pameran.namaPameran,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(pameran.lokasi,
                            style: const TextStyle(fontSize: 13, color: Colors.black54)),
                        const SizedBox(height: 12),
                        Text(
                          pameran.deskripsi ?? 'Tidak ada deskripsi.',
                          style: const TextStyle(fontSize: 13, height: 1.5),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A3B32),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(ctx);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TicketOrderPage(pameran: pameran),
                                ),
                              );
                            },
                            child: const Text('Beli Tiket'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}