import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/theme.dart';
import '../models/ticket_view_model.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';

class TicketListPage extends StatefulWidget {
  const TicketListPage({super.key});

  @override
  State<TicketListPage> createState() => _TicketListPageState();
}

class _TicketListPageState extends State<TicketListPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTickets());
  }

  void _loadTickets() {
    final idCustomer = context.read<AuthProvider>().profile?.id;
    if (idCustomer == null) return;
    context.read<OrderProvider>().loadMyTickets(idCustomer);
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

  List<TicketViewModel> _filteredList(List<TicketViewModel> list) {
    if (_searchQuery.trim().isEmpty) return list;
    final query = _searchQuery.trim().toLowerCase();
    return list.where((t) => t.namaPameran.toLowerCase().contains(query)).toList();
  }

  void _showTicketDetail(TicketViewModel ticket) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _TicketDetailSheet(ticket: ticket),
    );
  }

  @override
  Widget build(BuildContext context) {
    final namaUser = context.watch<AuthProvider>().profile?.namaUser ?? 'Pengguna';
    final orderProvider = context.watch<OrderProvider>();
    final filteredList = _filteredList(orderProvider.myTickets);

    return SafeArea(
      child: Column(
        children: [
          _buildHeaderBanner(namaUser),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _loadTickets(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchBar(),
                    const SizedBox(height: 20),
                    const Text(
                      'MY TICKET',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (orderProvider.isLoadingTickets)
                      const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (filteredList.isEmpty)
                      _buildEmptyState()
                    else
                      ...filteredList.map(
                        (ticket) => _TicketCard(
                          ticket: ticket,
                          onTap: () => _showTicketDetail(ticket),
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
          const Icon(Icons.confirmation_number_outlined, size: 40, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            _searchQuery.trim().isEmpty
                ? 'Belum ada tiket yang dibeli'
                : 'Tidak ditemukan hasil untuk "$_searchQuery"',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final TicketViewModel ticket;
  final VoidCallback? onTap;

  const _TicketCard({required this.ticket, this.onTap});

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
                child: ticket.posterUrl != null
                    ? CachedNetworkImage(
                        imageUrl: ticket.posterUrl!,
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
                    ticket.namaPameran,
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
                          dateFormat.format(ticket.tanggalKunjungan ?? ticket.tanggalMulai),
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
                          ticket.lokasi.toUpperCase(),
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
            if (ticket.statusCheckin)
              const Padding(
                padding: EdgeInsets.only(left: 4, top: 4),
                child: Icon(Icons.check_circle, color: AppColors.success, size: 20),
              )
            else
              const Padding(
                padding: EdgeInsets.only(left: 4, top: 4),
                child: Icon(Icons.qr_code_2, color: AppColors.textMuted, size: 20),
              ),
          ],
        ),
      ),
    );
  }
}

class _TicketDetailSheet extends StatelessWidget {
  final TicketViewModel ticket;

  const _TicketDetailSheet({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMMM yyyy');

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            ticket.namaPameran,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateFormat.format(ticket.tanggalKunjungan ?? ticket.tanggalMulai),
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: QrImageView(
              data: ticket.kodeQr,
              size: 180,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'a.n. ${ticket.namaPengunjung}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: ticket.statusCheckin
                  ? AppColors.success.withOpacity(0.15)
                  : AppColors.pending.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              ticket.statusCheckin ? 'Sudah Check-in' : 'Belum Check-in',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: ticket.statusCheckin ? AppColors.success : AppColors.pending,
              ),
            ),
          ),
        ],
      ),
    );
  }
}