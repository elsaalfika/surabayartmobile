import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pameran_model.dart';
import '../models/tiket_model.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import 'order_summary_page.dart';

class ListPengunjungPage extends StatefulWidget {
  final PameranModel pameran;
  final TiketModel tiket;
  final int jumlahTiket;
  final DateTime tanggalKunjungan; // <-- baru

  const ListPengunjungPage({
    super.key,
    required this.pameran,
    required this.tiket,
    required this.jumlahTiket,
    required this.tanggalKunjungan,
  });

  @override
  State<ListPengunjungPage> createState() => _ListPengunjungPageState();
}

class _ListPengunjungPageState extends State<ListPengunjungPage> {
  late List<TextEditingController> _controllers;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.jumlahTiket, (_) => TextEditingController());

    // Isi otomatis nama pengunjung pertama dengan nama akun yang login
    final auth = context.read<AuthProvider>();
    if (_controllers.isNotEmpty && auth.profile?.namaUser != null) {
      _controllers.first.text = auth.profile!.namaUser;
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final orderProvider = context.read<OrderProvider>();
    for (final controller in _controllers) {
      orderProvider.addItem(
        OrderItem(
          tiket: widget.tiket,
          pameran: widget.pameran,
          namaPengunjung: controller.text.trim(),
          tanggalKunjungan: widget.tanggalKunjungan,
        ),
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OrderSummaryPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1B18),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                  const Text('List Pengunjung',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2521),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.pameran.namaPameran,
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text('${widget.jumlahTiket} tiket',
                              style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.tanggalKunjungan.day}/${widget.tanggalKunjungan.month}/${widget.tanggalKunjungan.year}',
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Isi nama pengunjung untuk setiap tiket:',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 12),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView.separated(
                    itemCount: _controllers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return TextFormField(
                        controller: _controllers[index],
                        style: const TextStyle(color: Colors.white),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                        decoration: InputDecoration(
                          hintText: 'Nama pengunjung ${index + 1}',
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.08),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      );
                    },
                  ),
                ),
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
                  onPressed: _submit,
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }
}