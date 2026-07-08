import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/pameran_provider.dart';
import '../services/pameran_service.dart';

class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _namaController = TextEditingController();
  final _hargaController = TextEditingController();
  final _lokasiController = TextEditingController();
  final _kuotaController = TextEditingController();
  final _deskripsiController = TextEditingController();

  DateTime? _tanggalMulai;
  DateTime? _tanggalSelesai;
  TimeOfDay? _waktuMulai;
  TimeOfDay? _waktuSelesai;

  Uint8List? _posterBytes;
  String? _posterExt;
  String? _posterName;

  Uint8List? _qrBytes;
  String? _qrExt;
  String? _qrName;

  bool _saving = false;

  static const _allowedExt = ['jpg', 'jpeg', 'png'];
  static const _maxSizeBytes = 5 * 1024 * 1024;

  Future<void> _pickTanggal() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: DateTime(now.year + 2),
      initialDateRange: (_tanggalMulai != null && _tanggalSelesai != null)
          ? DateTimeRange(start: _tanggalMulai!, end: _tanggalSelesai!)
          : null,
    );
    if (range != null) {
      setState(() {
        _tanggalMulai = range.start;
        _tanggalSelesai = range.end;
      });
    }
  }

  Future<void> _pickWaktu({required bool isMulai}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (isMulai ? _waktuMulai : _waktuSelesai) ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isMulai) {
          _waktuMulai = picked;
        } else {
          _waktuSelesai = picked;
        }
      });
    }
  }

  Future<void> _pickImage({required bool isPoster}) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked == null) return;

    final ext = picked.name.split('.').last.toLowerCase();
    if (!_allowedExt.contains(ext)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Format harus JPG, JPEG, atau PNG')),
      );
      return;
    }

    final bytes = await picked.readAsBytes();
    if (bytes.lengthInBytes > _maxSizeBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ukuran file maksimal 5MB')),
      );
      return;
    }

    setState(() {
      if (isPoster) {
        _posterBytes = bytes;
        _posterExt = ext;
        _posterName = picked.name;
      } else {
        _qrBytes = bytes;
        _qrExt = ext;
        _qrName = picked.name;
      }
    });
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  String _formatDateShort(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year.toString().substring(2)}';
  }

  Future<void> _save() async {
    if (_namaController.text.trim().isEmpty ||
        _tanggalMulai == null ||
        _tanggalSelesai == null ||
        _waktuMulai == null ||
        _waktuSelesai == null ||
        _hargaController.text.trim().isEmpty ||
        _kuotaController.text.trim().isEmpty ||
        _lokasiController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi semua field wajib terlebih dahulu')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final organizerId = auth.profile?.id;
    if (organizerId == null) return;

    setState(() => _saving = true);

    final pameranProvider = context.read<PameranProvider>();
    final pameranService = PameranService();

    try {
      String? posterUrl;
      String? qrUrl;

      if (_posterBytes != null) {
        posterUrl = await pameranService.uploadPoster(
          organizerId,
          _posterBytes!,
          _posterExt!,
        );
      }
      if (_qrBytes != null) {
        qrUrl = await pameranService.uploadQrPembayaran(
          organizerId,
          _qrBytes!,
          _qrExt!,
        );
      }

      final success = await pameranProvider.createPameran(
        namaPameran: _namaController.text.trim(),
        deskripsi: _deskripsiController.text.trim(),
        lokasi: _lokasiController.text.trim(),
        tanggalMulai: _tanggalMulai!,
        tanggalSelesai: _tanggalSelesai!,
        waktuMulai: _formatTime(_waktuMulai!),
        waktuSelesai: _formatTime(_waktuSelesai!),
        hargaTiket: double.parse(_hargaController.text.trim()),
        kuota: int.parse(_kuotaController.text.trim()),
        posterUrl: posterUrl,
        qrPembayaranUrl: qrUrl,
        idPenyelenggara: organizerId,
      );

      if (!mounted) return;
      if (success) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(pameranProvider.errorMessage ?? 'Gagal menyimpan event')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/alun_alun_sby.png', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.6)),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create Your Event',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Nama Event'),
                        _textField(_namaController, 'Masukkan nama event'),
                        const SizedBox(height: 14),

                        _label('Tanggal'),
                        InkWell(
                          onTap: _pickTanggal,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F2F2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16, color: Colors.black45),
                                const SizedBox(width: 8),
                                Text(
                                  _tanggalMulai == null
                                      ? 'dd/mm/yy'
                                      : _formatDateShort(_tanggalMulai!),
                                  style: const TextStyle(fontSize: 13),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Icon(Icons.arrow_forward, size: 14),
                                ),
                                Text(
                                  _tanggalSelesai == null
                                      ? 'dd/mm/yy'
                                      : _formatDateShort(_tanggalSelesai!),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Harga Tiket'),
                                  _textField(_hargaController, 'Rp 10.xxx',
                                      keyboardType: TextInputType.number),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Lokasi'),
                                  _textField(_lokasiController, 'Lokasi event'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        _label('Kuota Tiket'),
                        _textField(_kuotaController, 'Jumlah kuota tiket',
                            keyboardType: TextInputType.number),
                        const SizedBox(height: 14),

                        _label('Waktu'),
                        Row(
                          children: [
                            Expanded(
                              child: _timePickerBox(
                                label: _waktuMulai == null
                                    ? '00:00'
                                    : _waktuMulai!.format(context),
                                onTap: () => _pickWaktu(isMulai: true),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(Icons.arrow_forward, size: 14, color: Colors.black45),
                            ),
                            Expanded(
                              child: _timePickerBox(
                                label: _waktuSelesai == null
                                    ? '00:00'
                                    : _waktuSelesai!.format(context),
                                onTap: () => _pickWaktu(isMulai: false),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        _label('Deskripsi'),
                        _textField(_deskripsiController, 'Tuliskan deskripsi event',
                            maxLines: 4),
                        const SizedBox(height: 14),

                        _label('Upload Poster'),
                        _uploadBox(
                          fileName: _posterName,
                          caption: 'PNG, JPG, atau JPEG (maks 5MB)',
                          onTap: () => _pickImage(isPoster: true),
                        ),
                        const SizedBox(height: 14),

                        _label('Upload QR Pembayaran'),
                        _uploadBox(
                          fileName: _qrName,
                          caption: 'PNG, JPG, atau JPEG (maks 5MB)',
                          onTap: () => _pickImage(isPoster: false),
                        ),
                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: _saving ? null : () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size.zero,
                                 tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                backgroundColor: const Color(0xFF4A3B32),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              onPressed: _saving ? null : _save,
                              child: _saving
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Save'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      );

  Widget _textField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: Colors.black38),
        filled: true,
        fillColor: const Color(0xFFF2F2F2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _timePickerBox({required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label, style: const TextStyle(fontSize: 13)),
      ),
    );
  }

  Widget _uploadBox({
    String? fileName,
    required String caption,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          children: [
            Text(
              fileName ?? 'Klik untuk mengunggah',
              style: const TextStyle(
                fontSize: 13,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(caption, style: const TextStyle(fontSize: 10, color: Colors.black45)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _hargaController.dispose();
    _lokasiController.dispose();
    _kuotaController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }
}