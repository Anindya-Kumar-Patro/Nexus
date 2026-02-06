import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/profile/presentation/profile_setup_screen.dart';
import '../features/auth/presentation/login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;

    // 1. If no session, go to Login
    if (session == null) {
      return const LoginScreen();
    }

    // 2. Check if profile exists using a FutureBuilder
    return FutureBuilder(
      future: supabase
          .from('profiles')
          .select()
          .eq('id', session.user.id)
          .maybeSingle(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // If data is null, they haven't filled their profile yet
        if (snapshot.data == null) {
          return const ProfileSetupScreen();
        }

        // Profile exists! Go to Home
        return const HomeScreen();
      },
    );
  }
}