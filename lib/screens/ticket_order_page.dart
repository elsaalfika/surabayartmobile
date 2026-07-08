import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/pameran_model.dart';
import '../models/tiket_model.dart';
import '../providers/pameran_provider.dart';
import 'list_pengunjung_page.dart';

class TicketOrderPage extends StatefulWidget {
  final PameranModel pameran;
  const TicketOrderPage({super.key, required this.pameran});

  @override
  State<TicketOrderPage> createState() => _TicketOrderPageState();
}

class _TicketOrderPageState extends State<TicketOrderPage> {
  int _qty = 1;
  bool _loading = true;
  TiketModel? _tiket;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTiket());
  }

  Future<void> _loadTiket() async {
    final provider = context.read<PameranProvider>();
    final list = await provider.loadTiket(widget.pameran.idPameran);
    if (mounted) {
      setState(() {
        _tiket = list.isNotEmpty ? list.first : null;
        _loading = false;
      });
    }
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

  DateTime? _tanggalKunjungan;

  Future<void> _pickTanggalKunjungan() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.pameran.tanggalMulai,
      firstDate: widget.pameran.tanggalMulai,
      lastDate: widget.pameran.tanggalSelesai,
    );
    if (picked != null) {
      setState(() => _tanggalKunjungan = picked);
    }
  }

  void _increment() {
    if (_tiket != null && _qty < _tiket!.sisaTiket) {
      setState(() => _qty++);
    }
  }

  void _decrement() {
    if (_qty > 1) setState(() => _qty--);
  }

  void _goToPengunjung() {
    if (_tiket == null) return;
    if (_tanggalKunjungan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal kunjungan terlebih dahulu')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ListPengunjungPage(
          pameran: widget.pameran,
          tiket: _tiket!,
          jumlahTiket: _qty,
          tanggalKunjungan: _tanggalKunjungan!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pameran = widget.pameran;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1B18),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _tiket == null
                ? const Center(
                    child: Text('Tiket untuk event ini belum tersedia.',
                        style: TextStyle(color: Colors.white70)),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            InkWell(
                              onTap: () => Navigator.pop(context),
                              child: const Icon(Icons.arrow_back, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            const Text('Selamat Datang!',
                                style: TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Hero(
                            tag: 'poster_${pameran.idPameran}',
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: pameran.posterUrl != null
                                  ? Image.network(pameran.posterUrl!, fit: BoxFit.cover)
                                  : Container(color: AppColors.border),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(pameran.namaPameran,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: Colors.white54),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(pameran.lokasi,
                                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.white54),
                            const SizedBox(width: 4),
                            Text(
                              '${_formatDate(pameran.tanggalMulai)} - ${_formatDate(pameran.tanggalSelesai)}',
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          pameran.deskripsi ?? 'Tidak ada deskripsi.',
                          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Harga Tiket',
                                  style: TextStyle(fontSize: 12, color: Colors.black45)),
                              const SizedBox(height: 4),
                              Text('Rp${_formatRupiah(_tiket!.hargaTiket)}',
                                  style: const TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text('Tersisa ${_tiket!.sisaTiket} tiket',
                                  style: const TextStyle(fontSize: 11, color: Colors.black38)),
                              const SizedBox(height: 16),
                              InkWell(
                                onTap: _pickTanggalKunjungan,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF2F2F2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.event_outlined, size: 16, color: Colors.black45),
                                      const SizedBox(width: 8),
                                      Text(
                                        _tanggalKunjungan == null
                                            ? 'Pilih tanggal kunjungan'
                                            : _formatDate(_tanggalKunjungan!),
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: _tanggalKunjungan == null ? Colors.black38 : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Jumlah Tiket',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  Row(
                                    children: [
                                      _qtyButton(Icons.remove, _decrement),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Text('$_qty',
                                            style: const TextStyle(
                                                fontSize: 15, fontWeight: FontWeight.w700)),
                                      ),
                                      _qtyButton(Icons.add, _increment),
                                    ],
                                  ),
                                ],
                              ),
                              const Divider(height: 28),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total Harga',
                                      style: TextStyle(fontSize: 13, color: Colors.black54)),
                                  Text(
                                    'Rp${_formatRupiah(_tiket!.hargaTiket * _qty)}',
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
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
                                  onPressed: _tiket!.sisaTiket == 0 ? null : _goToPengunjung,
                                  child: Text(
                                    _tiket!.sisaTiket == 0 ? 'Tiket Habis' : 'Book',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}