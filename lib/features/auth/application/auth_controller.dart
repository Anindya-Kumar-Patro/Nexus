import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_controller.g.dart';

@riverpod
class AuthController extends _$AuthController {
  @override
  FutureOr<void> build() {
    // Initial state is "idle" (not loading)
  }

  Future<void> signUp({required String email, required String password}) async {
    state = const AsyncValue.loading(); // Show loading spinner
    
    // 1. Client-Side Check for IITB Email
    if (!email.contains('iitb.ac.in') && !email.contains('som.iitb.ac.in')) {
      state = AsyncValue.error("Please use your IIT Bombay email (@iitb.ac.in)", StackTrace.current);
      return;
    }

    // 2. Call Supabase
    state = await AsyncValue.guard(() async {
      await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );
    });
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    });
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
  }
}