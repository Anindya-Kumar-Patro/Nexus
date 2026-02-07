import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _profileData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _getProfile();
  }

  Future<void> _getProfile() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      
      if (mounted) {
        setState(() {
          _profileData = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    await _supabase.auth.signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("My Profile", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B3C73))),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _signOut,
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Color(0xFF1B3C73),
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _profileData?['full_name'] ?? "User Name",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _profileData?['department'] ?? "IIT Bombay",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  _buildProfileTile(Icons.email, "Email", _supabase.auth.currentUser?.email ?? ""),
                  _buildProfileTile(Icons.link, "LinkedIn", _profileData?['linkedin_url'] ?? "Not linked"),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {}, // Add edit logic later
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B3C73),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1B3C73)),
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black)),
    );
  }
}