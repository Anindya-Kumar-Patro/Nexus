import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/main_drawer.dart'; 
import '../application/feed_controller.dart';
import 'venture_card.dart';

class MyVenturesScreen extends ConsumerWidget {
  const MyVenturesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myVenturesAsync = ref.watch(myVenturesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Ventures"),
      ),
      drawer: const MainDrawer(), // The Drawer Menu
      body: RefreshIndicator(
        onRefresh: () async {
          return ref.refresh(myVenturesProvider.future);
        },
        child: myVenturesAsync.when(
          data: (ventures) {
            if (ventures.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text("You haven't posted any ideas yet."),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: ventures.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return VentureCard(venture: ventures[index]);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text("Error: $err")),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1B3C73),
        onPressed: () => context.push('/create-venture'),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}