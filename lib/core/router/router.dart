import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../features/auth/presentation/login_screen.dart';
import '../../../features/home/presentation/home_screen.dart';
import '../../../features/profile/presentation/profile_setup_screen.dart';
import '../../../features/ventures/presentation/create_venture_screen.dart';
import '../../../features/ventures/presentation/venture_detail_screen.dart';
import '../../../features/ventures/domain/venture_model.dart'; 
import '../../../features/ventures/presentation/my_ventures_screen.dart';
// FIX: ADD THIS IMPORT
import '../../../features/ventures/presentation/saved_ventures_screen.dart';
import '../../../features/chat/presentation/inbox_screen.dart';
import '../../../features/chat/presentation/chat_screen.dart';
import '../../../features/home/presentation/main_navigation.dart';
part 'router.g.dart';

@riverpod
GoRouter router(RouterRef ref) {
  // 1. Get the current Auth State (Listen to changes)
  final authState = Supabase.instance.client.auth.onAuthStateChange;
  
  return GoRouter(
    initialLocation: '/home', // Default target
    refreshListenable: GoRouterRefreshStream(authState), // Refresh if auth changes
    
    redirect: (context, state) async {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggingIn = state.uri.toString() == '/login';

      // Scenario 1: Not Logged In -> Force Login
      if (session == null) {
        return '/login';
      }

      // Scenario 2: Logged In (and trying to see Login page) -> Go Home
      if (isLoggingIn) {
         return '/home';
      }

      return null; // Let them go where they want
    },
    
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainNavigation(),
      ),
      GoRoute(
        path: '/create-venture',
        builder: (context, state) {
          final ventureToEdit = state.extra as Venture?;
          return CreateVentureScreen(ventureToEdit: ventureToEdit);
        },
      ),
      GoRoute(
        path: '/venture-detail',
        builder: (context, state) {
          if (state.extra == null) {
            return const HomeScreen();
          }
          final venture = state.extra as Venture; 
          return VentureDetailScreen(venture: venture);
        },
      ),
      GoRoute(
        path: '/my-ventures',
        builder: (context, state) => const MyVenturesScreen(),
      ),
      // FIX: ADD THIS ROUTE
      GoRoute(
        path: '/saved-ideas',
        builder: (context, state) => const SavedVenturesScreen(),
      ),
      GoRoute(
        path: '/inbox',
        builder: (context, state) => const InboxScreen(),
      ),
      GoRoute(
        path: '/chat/:requestId/:title', 
        builder: (context, state) => ChatScreen(
          requestId: state.pathParameters['requestId']!,
          ventureTitle: state.pathParameters['title']!,
        ),
      ),
    ],
  );
}

// Helper to make the Router listen to a Stream
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}