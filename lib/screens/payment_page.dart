import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _confirmed = false;
  bool _loading = false;

  Future<void> _confirmBayar() async {
    setState(() => _loading = true);
    final orderProvider = context.read<OrderProvider>();
    final success = await orderProvider.konfirmasiPembayaran('qris');
    if (!mounted) return;
    setState(() {
      _loading = false;
      _confirmed = success;
    });
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(orderProvider.errorMessage ?? 'Konfirmasi gagal')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final transaksi = orderProvider.lastTransaksi;

    final qrUrl = orderProvider.cart.isNotEmpty
        ? orderProvider.cart.first.pameran.qrPembayaranUrl
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1B18),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _confirmed
                ? _buildThankYou(context)
                : _buildQrisPrompt(context, orderProvider, transaksi, qrUrl),
          ),
        ),
      ),
    );
  }

  Widget _buildQrisPrompt(
    BuildContext context,
    OrderProvider orderProvider,
    dynamic transaksi,
    String? qrUrl,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2521),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Scan QR untuk membayar',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: qrUrl != null
                ? Image.network(
                    qrUrl,
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const SizedBox(
                        width: 200,
                        height: 200,
                        child: Center(child: CircularProgressIndicator(color: Colors.white70)),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      width: 200,
                      height: 200,
                      color: Colors.white10,
                      child: const Icon(Icons.qr_code_2, size: 80, color: Colors.white38),
                    ),
                  )
                : Container(
                    width: 200,
                    height: 200,
                    color: Colors.white10,
                    padding: const EdgeInsets.all(16),
                    child: const Center(
                      child: Text(
                        'Organizer belum upload QR pembayaran.\nHubungi organizer secara manual.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            transaksi != null ? 'Total: Rp${transaksi.totalHarga.toStringAsFixed(0)}' : '',
            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          _buildBuktiBayarPicker(orderProvider),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A3B32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              onPressed: (_loading || orderProvider.buktiBayarFile == null) ? null : _confirmBayar,
              child: _loading
                  ? const SizedBox(
                      height: 16, width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Konfirmasi Pembayaran'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuktiBayarPicker(OrderProvider orderProvider) {
    final previewBytes = orderProvider.buktiBayarPreviewBytes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload Bukti Pembayaran',
          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: orderProvider.pickBuktiBayar,
          child: Container(
            width: double.infinity,
            height: previewBytes != null ? 160 : 100,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24, style: BorderStyle.solid),
            ),
            clipBehavior: Clip.antiAlias,
            child: previewBytes != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.memory(previewBytes, fit: BoxFit.cover),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: orderProvider.clearBuktiBayar,
                          child: const CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.black54,
                            child: Icon(Icons.close, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  )
                : const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.upload_file, color: Colors.white54, size: 24),
                        SizedBox(height: 6),
                        Text(
                          'Tap untuk pilih gambar',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        if (previewBytes == null) ...[
          const SizedBox(height: 6),
          const Text(
            'Wajib diisi sebelum bisa konfirmasi pembayaran.',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ],
    );
  }

  Widget _buildThankYou(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2521),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
            child: const Icon(Icons.mail_outline, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 16),
          const Text('THANK YOU!',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text(
            'Tiketmu sudah tersimpan.\nCek e-tiket di halaman My Ticket.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF2A2521),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text('Lihat Tiket'),
            ),
          ),
        ],
      ),
    );
  }
}