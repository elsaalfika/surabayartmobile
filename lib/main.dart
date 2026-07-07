import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants.dart';
import 'core/theme.dart';

import 'providers/auth_provider.dart';
import 'providers/favorite_provider.dart';
import 'providers/order_provider.dart';
import 'providers/pameran_provider.dart';

import 'screens/home_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabasePublishableKey, // parameter tetap bernama anonKey
  );

  runApp(const SurabayArtApp());
}

class SurabayArtApp extends StatelessWidget {
  const SurabayArtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider()..checkCurrentSession(),
        ),
        ChangeNotifierProvider<PameranProvider>(
          create: (_) => PameranProvider(),
        ),
        ChangeNotifierProvider<OrderProvider>(
          create: (_) => OrderProvider(),
        ),
        ChangeNotifierProvider<FavoriteProvider>(
          create: (_) => FavoriteProvider(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SurabayArt',
        theme: AppTheme.lightTheme,
        home: const HomeRouter(), // HomeRouter sudah handle semua status auth
      ),
    );
  }
}