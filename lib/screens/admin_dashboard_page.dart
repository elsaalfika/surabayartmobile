import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/admin_provider.dart';
import '../models/profile_model.dart';
import '../models/pameran_model.dart';

enum _AdminTab { validasi, event, user }

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  _AdminTab _selectedTab = _AdminTab.validasi;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Future<void> _loadAll() async {
    final admin = context.read<AdminProvider>();
    await admin.loadOverview();
    await admin.loadAllEvents();
    await admin.loadCustomers();
    await admin.loadOrganizers();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

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
                child: _buildOverviewCard(admin),
              ),
            ),
            if (admin.errorMessage != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _buildErrorBanner(admin.errorMessage!),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Actions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildTabSelector(),
                    if (_selectedTab != _AdminTab.validasi) ...[
                      const SizedBox(height: 10),
                      _buildSearchField(),
                    ],
                  ],
                ),
              ),
            ),
            if (admin.isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator(color: Colors.white)),
                ),
              )
            else
              _buildContentSliver(admin),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
        ],
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
                child: const Icon(Icons.shield_outlined, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Kelola pengguna, penyelenggara, dan validasi event',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _handleLogout,
                child: Container(
                  width: 44,
                  height: 44,
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
        content: const Text('Yakin ingin keluar dari akun admin?'),
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

  Widget _buildOverviewCard(AdminProvider admin) {
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
              Expanded(child: _statTile('Total Pengguna', '${admin.totalPengguna}', 'Akun terdaftar')),
              const SizedBox(width: 10),
              Expanded(child: _statTile('Total Organizer', '${admin.totalOrganizer}', 'Penyelenggara aktif')),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _statTile('Event Aktif', '${admin.eventAktifCount}', 'Sudah disetujui')),
              const SizedBox(width: 10),
              Expanded(child: _statTile('Menunggu Validasi', '${admin.menungguValidasiCount}', 'Perlu ditinjau')),
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

  Widget _buildTabSelector() {
    Widget pill(String label, _AdminTab tab) {
      final selected = _selectedTab == tab;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _selectedTab = tab),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF4A3B32) : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        pill('Validasi', _AdminTab.validasi),
        const SizedBox(width: 8),
        pill('Event', _AdminTab.event),
        const SizedBox(width: 8),
        pill('User', _AdminTab.user),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: 'Search',
        hintStyle: const TextStyle(fontSize: 12, color: Colors.black38),
        prefixIcon: const Icon(Icons.search, size: 18),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildContentSliver(AdminProvider admin) {
    switch (_selectedTab) {
      case _AdminTab.validasi:
        return _buildValidasiList(admin);
      case _AdminTab.event:
        return _buildEventList(admin);
      case _AdminTab.user:
        return _buildUserList(admin);
    }
  }

  // ---------------- TAB: VALIDASI ----------------

  Widget _buildValidasiList(AdminProvider admin) {
    if (admin.pendingEvents.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text('Tidak ada event yang menunggu validasi.',
                style: TextStyle(color: Colors.white54)),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final pameran = admin.pendingEvents[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildEventValidationCard(pameran, admin),
            );
          },
          childCount: admin.pendingEvents.length,
        ),
      ),
    );
  }

  Widget _buildEventValidationCard(PameranModel pameran, AdminProvider admin) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  pameran.namaPameran,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              _statusBadge('pending'),
            ],
          ),
          const SizedBox(height: 8),
          _infoRow('Tanggal',
              '${_formatDate(pameran.tanggalMulai)} - ${_formatDate(pameran.tanggalSelesai)}'),
          _infoRow('Lokasi', pameran.lokasi),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size.zero,
                    backgroundColor: const Color(0xFF3F7D4C),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () => _handleApprove(pameran, admin),
                  child: const Text('Setujui Permintaan', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size.zero,
                    backgroundColor: const Color(0xFFB4483C),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () => _handleReject(pameran, admin),
                  child: const Text('Tolak Permintaan', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleApprove(PameranModel pameran, AdminProvider admin) async {
    final idAdmin = context.read<AuthProvider>().profile?.id;
    if (idAdmin == null) return;
    final ok = await admin.approveEvent(pameran.idPameran, idAdmin);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Event disetujui' : (admin.errorMessage ?? 'Gagal'))),
    );
  }

  Future<void> _handleReject(PameranModel pameran, AdminProvider admin) async {
    final idAdmin = context.read<AuthProvider>().profile?.id;
    if (idAdmin == null) return;
    final ok = await admin.rejectEvent(pameran.idPameran, idAdmin);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Event ditolak' : (admin.errorMessage ?? 'Gagal'))),
    );
  }

  // ---------------- TAB: EVENT (semua event, view-only) ----------------

  Widget _buildEventList(AdminProvider admin) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? admin.allEvents
        : admin.allEvents
            .where((e) =>
                e.namaPameran.toLowerCase().contains(query) ||
                e.lokasi.toLowerCase().contains(query))
            .toList();

    if (filtered.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              query.isEmpty ? 'Belum ada event.' : 'Tidak ditemukan.',
              style: const TextStyle(color: Colors.white54),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final pameran = filtered[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildEventInfoCard(pameran),
            );
          },
          childCount: filtered.length,
        ),
      ),
    );
  }

  Widget _buildEventInfoCard(PameranModel pameran) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  pameran.namaPameran,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              _statusBadge(pameran.statusVerifikasi),
            ],
          ),
          const SizedBox(height: 8),
          _infoRow('Tanggal',
              '${_formatDate(pameran.tanggalMulai)} - ${_formatDate(pameran.tanggalSelesai)}'),
          _infoRow('Lokasi', pameran.lokasi),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color bg;
    String label;
    switch (status) {
      case 'disetujui':
        bg = const Color(0xFF3F7D4C);
        label = 'Disetujui';
        break;
      case 'ditolak':
        bg = const Color(0xFFB4483C);
        label = 'Ditolak';
        break;
      default:
        bg = const Color(0xFFFFC107);
        label = 'Pending';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: status == 'pending' || status.isEmpty ? Colors.black87 : Colors.white,
        ),
      ),
    );
  }

  // ---------------- TAB: USER (customer + organizer digabung) ----------------

  Widget _buildUserList(AdminProvider admin) {
    final query = _searchController.text.trim().toLowerCase();
    final list = admin.allUsers;
    final filtered = query.isEmpty
        ? list
        : list
            .where((u) =>
                u.namaUser.toLowerCase().contains(query) ||
                u.emailUser.toLowerCase().contains(query))
            .toList();

    if (filtered.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              query.isEmpty ? 'Belum ada data.' : 'Tidak ditemukan.',
              style: const TextStyle(color: Colors.white54),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final user = filtered[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildProfileCard(user, admin: admin),
            );
          },
          childCount: filtered.length,
        ),
      ),
    );
  }

  Widget _buildProfileCard(ProfileModel user, {required AdminProvider admin}) {
    final aktif = user.statusAkun == 'aktif';
    final isOrganizer = user.isOrganizer;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(user.namaUser,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOrganizer ? const Color(0xFF4A3B32) : const Color(0xFF6B8CAE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isOrganizer ? 'Organizer' : 'Customer',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (isOrganizer && (user.nik?.isNotEmpty ?? false)) _infoRow('NIK', user.nik!),
          _infoRow('Email', user.emailUser),
          if (isOrganizer && (user.namaInstansi?.isNotEmpty ?? false))
            _infoRow('Instansi', user.namaInstansi!),
          _infoRow('Status', aktif ? 'Aktif' : 'Nonaktif'),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => _showEditDialog(user, isOrganizer, admin),
                child: const Text('Edit'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => _handleToggleBlock(user, isOrganizer, admin),
                child: Text(
                  aktif ? 'Blokir' : 'Aktifkan',
                  style: TextStyle(color: aktif ? Colors.red : Colors.green),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleToggleBlock(ProfileModel user, bool isOrganizer, AdminProvider admin) async {
    final ok = await admin.toggleBlockUser(user, isOrganizer: isOrganizer);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Status akun diperbarui' : (admin.errorMessage ?? 'Gagal'))),
    );
  }

  Future<void> _showEditDialog(ProfileModel user, bool isOrganizer, AdminProvider admin) async {
    final namaController = TextEditingController(text: user.namaUser);
    final instansiController = TextEditingController(text: user.namaInstansi ?? '');
    final nikController = TextEditingController(text: user.nik ?? '');
    final telpController = TextEditingController(text: user.telpUser ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profil'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: namaController, decoration: const InputDecoration(labelText: 'Nama')),
              if (isOrganizer) ...[
                TextField(controller: instansiController, decoration: const InputDecoration(labelText: 'Instansi')),
                TextField(controller: nikController, decoration: const InputDecoration(labelText: 'NIK')),
              ],
              TextField(controller: telpController, decoration: const InputDecoration(labelText: 'No. Telepon')),
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
      final ok = await admin.editProfile(
        user: user,
        isOrganizer: isOrganizer,
        namaUser: namaController.text.trim(),
        namaInstansi: isOrganizer ? instansiController.text.trim() : null,
        nik: isOrganizer ? nikController.text.trim() : null,
        telpUser: telpController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Profil diperbarui' : (admin.errorMessage ?? 'Gagal menyimpan'))),
      );
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(color: Colors.black45)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const bulan = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    return '${d.day} ${bulan[d.month - 1]} ${d.year}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}