import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_background.dart';
import 'login_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nikController = TextEditingController(); // organizer
  final _instansiController = TextEditingController(); // organizer

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  String get _selectedRole {
    switch (_tabController.index) {
      case 1:
        return 'organizer';
      default:
        return 'customer';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      namaUser: _nameController.text.trim(),
      role: _selectedRole,
      namaInstansi:
          _selectedRole == 'organizer' ? _instansiController.text.trim() : null,
      nik: _selectedRole == 'organizer' ? _nikController.text.trim() : null,
    );

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Registrasi gagal, coba lagi'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registrasi sukses! Konfirmasi email anda.')),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  void _goToLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/alun_alun_sby.png', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.55)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'SIGN UP',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TabBar(
                              controller: _tabController,
                              onTap: (_) => setState(() {}),
                              isScrollable: true,
                              tabAlignment: TabAlignment.center,
                              indicatorSize: TabBarIndicatorSize.label,
                              labelColor: Colors.white,
                              unselectedLabelColor: Colors.white38,
                              indicatorColor: Colors.white,
                              labelStyle: const TextStyle(fontSize: 12),
                              tabs: const [
                                Tab(text: 'as customer'),
                                Tab(text: 'as organizer'),
                              ],
                            ),
                            const SizedBox(height: 24),
                                    _field(_nameController, 'name', icon: Icons.person_outline),
                                    const SizedBox(height: 12),
                                    if (_selectedRole == 'organizer') ...[
                                      _field(_nikController, 'NIK', icon: Icons.badge_outlined),
                                      const SizedBox(height: 12),
                                    ],
                                    _field(_emailController, 'email',
                                        icon: Icons.email_outlined,
                                        validator: (v) => (v == null || !v.contains('@'))
                                            ? 'Email tidak valid'
                                            : null),
                                    const SizedBox(height: 12),
                                    if (_selectedRole == 'organizer') ...[
                                      _field(_instansiController, 'instansi',
                                          icon: Icons.apartment_outlined),
                                      const SizedBox(height: 12),
                                    ],
                                    _field(_passwordController, 'password',
                                        icon: Icons.lock_outline,
                                        obscure: true,
                                        validator: (v) => (v == null || v.length < 6)
                                            ? 'Minimal 6 karakter'
                                            : null),
                                    const SizedBox(height: 20),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF4A3B32),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(24),
                                        ),
                                      ),
                                      onPressed: auth.isLoading ? null : _submit,
                                      child: auth.isLoading
                                          ? const SizedBox(
                                              height: 18,
                                              width: 18,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2, color: Colors.white),
                                            )
                                          : const Text('SIGN UP'),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          "sudah punya akun? ",
                                          style: TextStyle(color: Colors.white54, fontSize: 13),
                                        ),
                                        GestureDetector(
                                          onTap: _goToLogin,
                                          child: const Text(
                                            'sign in',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String hint, {
    IconData? icon,
    bool obscure = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator ?? (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, color: Colors.white38, size: 18) : null,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withOpacity(0.12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nikController.dispose();
    _instansiController.dispose();
    super.dispose();
  }
}