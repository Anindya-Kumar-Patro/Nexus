import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/widgets/main_drawer.dart';
import '../../ventures/application/feed_controller.dart';
import '../../ventures/presentation/venture_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _checkProfile();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final profile = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (profile == null || profile['full_name'] == null || (profile['full_name'] as String).isEmpty) {
      if (mounted) {
        context.go('/profile-setup');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(feedControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Nexus", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      drawer: const MainDrawer(),
      body: Column(
        children: [
          // --- 1. SEARCH BAR ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              // FIX: Update state immediately on change
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase().trim();
                });
              },
              decoration: InputDecoration(
                hintText: "Search ideas, roles, descriptions...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                        FocusScope.of(context).unfocus();
                      },
                    )
                  : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // --- 2. VENTURE LIST ---
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                return ref.refresh(feedControllerProvider.future);
              },
              child: feedAsync.when(
                data: (ventures) {
                  // --- SEARCH LOGIC (Improved) ---
                  final filtered = ventures.where((v) {
                    if (_searchQuery.isEmpty) return true; // Show all if empty

                    final title = v.title.toLowerCase();
                    final oneLiner = v.oneLiner.toLowerCase();
                    final desc = v.description.toLowerCase(); // FIX: Added Description
                    final roles = v.lookingFor.join(' ').toLowerCase();

                    return title.contains(_searchQuery) || 
                           oneLiner.contains(_searchQuery) ||
                           desc.contains(_searchQuery) ||
                           roles.contains(_searchQuery);
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            "No results found for '$_searchQuery'",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    // FIX: Dismiss keyboard when dragging list
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return VentureCard(venture: filtered[index]);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text("Error: $err")),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1B3C73),
        onPressed: () {
           context.push('/create-venture');
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}