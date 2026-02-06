import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'profile_controller.g.dart';

@riverpod
class ProfileController extends _$ProfileController {
  @override
  FutureOr<void> build() {
    // Initial state is idle
  }

  Future<void> updateProfile({
    required String fullName,
    required String rollNumber,
    required String department,
    required String role,
    String? linkedin,
  }) async {
    state = const AsyncValue.loading();
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      state = AsyncValue.error("User not logged in", StackTrace.current);
      return;
    }

    state = await AsyncValue.guard(() async {
      final updates = {
        'id': user.id, // CRITICAL: Link this profile to the logged-in user
        'full_name': fullName,
        'roll_number': rollNumber,
        'department': department,
        'role': role,
        'linkedin_url': linkedin,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Upsert = Update if exists, Insert if new
      await Supabase.instance.client.from('profiles').upsert(updates);
    });
  }
}