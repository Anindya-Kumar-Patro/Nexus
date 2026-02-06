import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/venture_model.dart';

part 'feed_controller.g.dart';

@riverpod
class FeedController extends _$FeedController {
  @override
  FutureOr<List<Venture>> build() async {
    return _fetchVentures();
  }

  Future<List<Venture>> _fetchVentures() async {
    try {
      final response = await Supabase.instance.client
          .from('ventures')
          .select()
          .eq('status', 'active') // Only show active ventures on global feed
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((ventureJson) => Venture.fromJson(ventureJson)).toList();
    } catch (e) {
      throw Exception('Failed to fetch feed: $e');
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchVentures());
  }
}

// --- RESTORING THE MISSING PROVIDER ---
@riverpod
Future<List<Venture>> myVentures(MyVenturesRef ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];

  final response = await Supabase.instance.client
      .from('ventures')
      .select()
      .eq('owner_id', user.id)
      .order('created_at', ascending: false);

  final List<dynamic> data = response as List<dynamic>;
  return data.map((ventureJson) => Venture.fromJson(ventureJson)).toList();
}