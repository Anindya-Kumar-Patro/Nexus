import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/venture_model.dart';

// Provides the list of saved UUIDs as Strings
final savedIdsProvider = StateNotifierProvider<SavedIdsNotifier, List<String>>((ref) {
  return SavedIdsNotifier();
});

class SavedIdsNotifier extends StateNotifier<List<String>> {
  SavedIdsNotifier() : super([]) {
    loadSavedIds();
  }

  Future<void> loadSavedIds() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await Supabase.instance.client
          .from('saved_ventures')
          .select('venture_id');

      final ids = (response as List).map((e) => e['venture_id'].toString()).toList();
      state = ids;
    } catch (e) {
      // Handle potential errors silently or log them
    }
  }

  Future<void> toggleSave(String ventureId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    if (state.contains(ventureId)) {
      state = state.where((id) => id != ventureId).toList();
      try {
        await Supabase.instance.client
            .from('saved_ventures')
            .delete()
            .eq('venture_id', ventureId)
            .eq('user_id', user.id);
      } catch (e) {
        state = [...state, ventureId]; 
      }
    } else {
      state = [...state, ventureId];
      try {
        await Supabase.instance.client
            .from('saved_ventures')
            .insert({'user_id': user.id, 'venture_id': ventureId});
      } catch (e) {
        state = state.where((id) => id != ventureId).toList();
      }
    }
  }
}

// Fetches the actual Venture objects for the Saved Screen
final savedVenturesListProvider = FutureProvider<List<Venture>>((ref) async {
  final savedIds = ref.watch(savedIdsProvider);
  
  if (savedIds.isEmpty) return [];

  // Use .filter with 'in' to bypass potential .in_ issues in package versions
  final response = await Supabase.instance.client
      .from('ventures')
      .select()
      .filter('id', 'in', savedIds);

  return (response as List).map((data) => Venture.fromJson(data)).toList();
});