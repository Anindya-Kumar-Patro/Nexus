import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'create_venture_controller.g.dart';

@riverpod
class CreateVentureController extends _$CreateVentureController {
  @override
  FutureOr<void> build() {
    // Initial state is idle
  }

  // --- CREATE ---
  Future<void> postVenture({
    required String title,
    required String oneLiner,
    required String description,
    required String stage,
    required List<String> lookingFor,
  }) async {
    state = const AsyncValue.loading();
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      state = AsyncValue.error("You must be logged in", StackTrace.current);
      return;
    }

    state = await AsyncValue.guard(() async {
      await Supabase.instance.client.from('ventures').insert({
        'owner_id': user.id, // CRITICAL: Links the venture to YOU
        'title': title,
        'one_liner': oneLiner,
        'description': description,
        'stage': stage,
        'looking_for_roles': lookingFor,
      });
    });
  }

  // --- UPDATE (Stricter Check) ---
  Future<void> updateVenture({
    required String ventureId,
    required String title,
    required String oneLiner,
    required String description,
    required String stage,
    required List<String> lookingFor,
  }) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      // We use .select() at the end to ask Supabase: "Return the row you just updated."
      final response = await Supabase.instance.client
          .from('ventures')
          .update({
            'title': title,
            'one_liner': oneLiner,
            'description': description,
            'stage': stage,
            'looking_for_roles': lookingFor,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', ventureId)
          .select(); 

      // If the list is empty, it means Supabase updated ZERO rows.
      // This happens if the ID doesn't exist OR (more likely) RLS blocked it because you aren't the owner.
      if (response.isEmpty) {
        throw "Update failed: You are not the owner of this venture.";
      }
    });
  }

  // --- DELETE (Stricter Check) ---
  Future<void> deleteVenture(String ventureId) async {
    state = const AsyncValue.loading();
    
    state = await AsyncValue.guard(() async {
      // We use .select() to confirm the delete actually happened.
      final response = await Supabase.instance.client
          .from('ventures')
          .delete()
          .eq('id', ventureId)
          .select();

      if (response.isEmpty) {
        throw "Delete failed: You are not the owner of this venture.";
      }
    });
  }
}