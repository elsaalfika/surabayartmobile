import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/pameran_provider.dart';
import '../models/pameran_model.dart';
import '../models/tiket_model.dart';
import 'create_event_page.dart';

class OrganizerDashboardPage extends StatefulWidget {
  const OrganizerDashboardPage({super.key});

  @override
  State<OrganizerDashboardPage> createState() => _OrganizerDashboardPageState();
}

class _OrganizerDashboardPageState extends State<OrganizerDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Future<void> _loadAll() async {
    final auth = context.read<AuthProvider>();
    final pameranProvider = context.read<PameranProvider>();
    final organizerId = auth.profile?.id;
    if (organizerId == null) return;

    await pameranProvider.loadMyEvent(organizerId);

    for (final pameran in pameranProvider.myEventList) {
      await pameranProvider.loadTiket(pameran.idPameran);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pameranProvider = context.watch<PameranProvider>();
    final myEvents = pameranProvider.myEventList;

    final totalEvent = myEvents.length;
    final eventAktif = myEvents.where((e) => e.isApproved).length;
    final menungguValidasi = myEvents.where((e) => e.isPending).length;

    int tiketTerjual = 0;
    for (final e in myEvents) {
      final tikets = pameranProvider.tiketPerPameran[e.idPameran] ?? [];
      for (final t in tikets) {
        tiketTerjual += t.tiketTerjual;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E1B18),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _buildOverviewCard(
                  totalEvent: totalEvent,
                  eventAktif: eventAktif,
                  tiketTerjual: tiketTerjual,
                  menungguValidasi: menungguValidasi,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _buildNewEventCard(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: const Text(
                  'My Event',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (pameranProvider.isLoading && myEvents.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator(color: Colors.white)),
                ),
              )
            else if (myEvents.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'Belum ada event yang diupload.',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final pameran = myEvents[index];
                      final tikets = pameranProvider.tiketPerPameran[pameran.idPameran] ?? [];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildEventCard(pameran, tikets),
                      );
                    },
                    childCount: myEvents.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        SizedBox(
          height: 170,
          width: double.infinity,
          child: Image.asset('assets/images/alun_alun_sby.png', fit: BoxFit.cover),
        ),
        Container(
          height: 170,
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5)),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 20,
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Organizer Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Kelola event dan pantau penjualan tiket',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _showEditProfileDialog,
                child: Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_outline, color: Colors.white, size: 20),
                ),
              ),
              GestureDetector(
                onTap: _handleLogout,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.logout, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Yakin ingin keluar dari akun?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await context.read<AuthProvider>().signOut();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _showEditProfileDialog() async {
    final auth = context.read<AuthProvider>();
    final me = auth.profile;
    if (me == null) return;

    final namaController = TextEditingController(text: me.namaUser);
    final instansiController = TextEditingController(text: me.namaInstansi ?? '');
    final nikController = TextEditingController(text: me.nik ?? '');
    final telpController = TextEditingController(text: me.telpUser ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profil Saya'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: namaController,
                decoration: const InputDecoration(labelText: 'Nama'),
              ),
              TextField(
                controller: instansiController,
                decoration: const InputDecoration(labelText: 'Instansi'),
              ),
              TextField(
                controller: nikController,
                decoration: const InputDecoration(labelText: 'NIK'),
              ),
              TextField(
                controller: telpController,
                decoration: const InputDecoration(labelText: 'No. Telepon'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simpan')),
        ],
      ),
    );

    if (saved == true) {
      final ok = await auth.updateOwnProfile(
        namaUser: namaController.text.trim(),
        namaInstansi: instansiController.text.trim(),
        nik: nikController.text.trim(),
        telpUser: telpController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Profil diperbarui' : (auth.errorMessage ?? 'Gagal menyimpan'))),
      );
    }
  }

  Widget _buildOverviewCard({
    required int totalEvent,
    required int eventAktif,
    required int tiketTerjual,
    required int menungguValidasi,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2521),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overview',
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _statTile('Total Event', '$totalEvent', 'Event terjadwal')),
              const SizedBox(width: 10),
              Expanded(child: _statTile('Event Aktif', '$eventAktif', 'Event sedang berjalan')),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _statTile('Tiket Terjual', '$tiketTerjual', 'Total tiket')),
              const SizedBox(width: 10),
              Expanded(child: _statTile('Menunggu Validasi', '$menungguValidasi', 'Event perlu persetujuan')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value, String caption) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF3A332C),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(caption, style: const TextStyle(color: Colors.white38, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildNewEventCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New Event',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              SizedBox(height: 2),
              Text('Buat event sekarang!',
                  style: TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),
          InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const CreateEventPage()),
              );
              if (result == true) {
                _loadAll(); 
              }
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFF2A2521),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(PameranModel p) {
    if (p.isApproved) return const Color(0xFF4CAF50);
    if (p.isRejected) return const Color(0xFFE53935);
    return const Color(0xFFFFC107); 
  }

  Widget _buildEventCard(PameranModel pameran, List<TiketModel> tikets) {
    final totalKuota = tikets.fold<int>(0, (sum, t) => sum + t.kuota);
    final totalTersisa = tikets.fold<int>(0, (sum, t) => sum + t.sisaTiket);
    final hargaMin = tikets.isEmpty
        ? null
        : tikets.map((t) => t.hargaTiket).reduce((a, b) => a < b ? a : b);

    final tanggalRange =
        '${_formatDate(pameran.tanggalMulai)} - ${_formatDate(pameran.tanggalSelesai)}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: _statusColor(pameran), width: 5)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pameran.namaPameran,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _infoRow('Tanggal', tanggalRange),
          _infoRow('Lokasi', pameran.lokasi),
          if (hargaMin != null) _infoRow('Harga', 'Rp${_formatRupiah(hargaMin)}'),
          if (tikets.isNotEmpty)
            _infoRow('Kuota Tiket', '$totalKuota',
                trailing: 'Tiket Tersisa\n$totalTersisa'),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () {},
                child: const Text('Edit'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => _confirmDelete(pameran),
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {String? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.black45)),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          if (trailing != null)
            Expanded(
              child: Text(
                trailing,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 11, color: Colors.black45),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const bulan = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${d.day} ${bulan[d.month - 1]} ${d.year}';
  }

  String _formatRupiah(double value) {
    final s = value.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }

  Future<void> _confirmDelete(PameranModel pameran) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Event'),
        content: Text('Yakin ingin menghapus "${pameran.namaPameran}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final auth = context.read<AuthProvider>();
      final organizerId = auth.profile?.id;
      if (organizerId != null) {
        await context.read<PameranProvider>().deletePameran(pameran.idPameran, organizerId);
      }
    }
  }
}