import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router/router.dart';
import 'core/theme/theme.dart';
import 'screens/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase (We will add real keys later)
  await Supabase.initialize(
    url: 'https://akfzyedpiyusulsatzcv.supabase.co',
    anonKey: 'sb_publishable_XzPjUXuRU58915jWpVy2Cg_3OC_vCG4',
  );

  // ProviderScope is the "Parent" widget for Riverpod state management
  runApp(const ProviderScope(child: NexusApp()));
}

class NexusApp extends ConsumerWidget {
  const NexusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the router provider
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Nexus IITB',
      theme: AppTheme.lightTheme,
      routerConfig: router, // Connects the navigation system
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nexus',
      home: const AuthWrapper(), // Start here!
    );
  }
}