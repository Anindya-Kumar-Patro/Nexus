import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/application/auth_controller.dart';

class MainDrawer extends ConsumerWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: Column(
        children: [
          // --- 1. ATTRACTIVE HEADER ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 20, left: 20, right: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B3C73), Color(0xFF2C5EAA)], // Nexus Blue Gradient
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Big Circular Avatar Icon
                Container(
                  padding: const EdgeInsets.all(3), // White border effect
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const CircleAvatar(
                    radius: 30,
                    backgroundColor: Color(0xFFE0E0E0),
                    child: Icon(Icons.person, size: 35, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Innovator",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  "Welcome to Nexus",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // --- 2. MENU ITEMS ---
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                ListTile(
                  leading: const Icon(Icons.home_outlined, color: Color(0xFF1B3C73)),
                  title: const Text('Home Feed'),
                  onTap: () {
                    context.pop();
                    context.go('/home');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.inventory_2_outlined, color: Color(0xFF1B3C73)),
                  title: const Text('My Ventures'),
                  onTap: () {
                    context.pop();
                    context.push('/my-ventures');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.favorite_outline, color: Color(0xFF1B3C73)),
                  title: const Text('Saved Ideas'),
                  onTap: () {
                    context.pop();
                    context.push('/saved-ideas');
                  },
                ),
                // Divider to separate "App" from "Account"
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(),
                ),
                ListTile(
                  leading: const Icon(Icons.person_outline, color: Color(0xFF1B3C73)),
                  title: const Text('Edit Profile'),
                  onTap: () {
                    context.pop();
                    context.push('/profile-setup');
                  },
                ),
              ],
            ),
          ),

          // --- 3. BOTTOM LOGOUT ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: Colors.red.shade50,
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: () {
                ref.read(authControllerProvider.notifier).logout();
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}