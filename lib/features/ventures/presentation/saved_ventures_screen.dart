import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/saved_provider.dart';
import 'venture_card.dart';

class SavedVenturesScreen extends ConsumerWidget {
  const SavedVenturesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedVenturesAsync = ref.watch(savedVenturesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Saved Ideas", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: savedVenturesAsync.when(
        data: (ventures) {
          if (ventures.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("You haven't saved any ideas yet.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: ventures.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) => VentureCard(venture: ventures[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
    );
  }
}