import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class HomeRouter extends StatelessWidget {
  const HomeRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final role = auth.profile?.role ?? 'customer';

    switch (role) {
      case 'admin':
        return const Scaffold(body: Center(child: Text('Admin Dashboard belum dibuat')));
      case 'organizer':
        return const Scaffold(body: Center(child: Text('Organizer Dashboard belum dibuat')));
      default:
        return const Scaffold(body: Center(child: Text('Home Page belum dibuat')));
    }
  }
}