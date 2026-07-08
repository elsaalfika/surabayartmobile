import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_page.dart';
import 'organizer_dashboard_page.dart';
import 'admin_dashboard_page.dart';

class HomeRouter extends StatelessWidget {
  const HomeRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.status == AuthStatus.unknown) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (auth.status == AuthStatus.unauthenticated) {
      return const LoginPage();
    }

    final role = auth.profile?.role ?? 'customer';

    switch (role) {
      case 'admin':
        return const AdminDashboardPage();
      case 'organizer':
        return const OrganizerDashboardPage();
      default:
        return const Scaffold(body: Center(child: Text('Home Page belum dibuat')));
    }
  }
}