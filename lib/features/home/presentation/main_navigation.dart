import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nexus/features/home/presentation/home_screen.dart';
import 'package:nexus/features/chat/presentation/inbox_screen.dart';
import 'package:nexus/features/chat/presentation/applied_screen.dart';
import 'package:nexus/features/profile/presentation/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  int _unreadCount = 0;
  final String _currentUserId = Supabase.instance.client.auth.currentUser!.id;
  late RealtimeChannel _badgeChannel;

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
    _setupBadgeRealtime();
  }

  Future<void> _fetchUnreadCount() async {
    try {
      // Corrected syntax for Supabase Flutter count
      final response = await Supabase.instance.client
          .from('messages')
          .select()
          .eq('receiver_id', _currentUserId)
          .eq('is_read', false)
          .count(CountOption.exact); // This is the modern way to get the count
      
      if (mounted) {
        setState(() => _unreadCount = response.count);
      }
    } catch (e) {
      debugPrint("Error fetching unread count: $e");
    }
  }

  void _setupBadgeRealtime() {
    _badgeChannel = Supabase.instance.client
        .channel('public:messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          callback: (payload) => _fetchUnreadCount(),
        )
        .subscribe();
  }

  @override
  void dispose() {
    Supabase.instance.client.removeChannel(_badgeChannel);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: [
        const HomeScreen(),
        const InboxScreen(),
        const AppliedScreen(),
        const ProfileScreen(),
      ]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1B3C73),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.explore), label: "Explore"),
          BottomNavigationBarItem(
            icon: Badge(
              label: Text('$_unreadCount'),
              isLabelVisible: _unreadCount > 0,
              child: const Icon(Icons.mail),
            ),
            label: "Inbox",
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.send), label: "Applied"),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}