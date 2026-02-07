import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class AppliedScreen extends StatefulWidget {
  const AppliedScreen({super.key});

  @override
  State<AppliedScreen> createState() => _AppliedScreenState();
}

class _AppliedScreenState extends State<AppliedScreen> {
  bool _isLoading = true;
  List<dynamic> _myApplications = [];
  final String _currentUserId = Supabase.instance.client.auth.currentUser!.id;
  late RealtimeChannel _appliedChannel;

  @override
  void initState() {
    super.initState();
    _fetchApplications();
    _setupAppliedRealtime();
  }

  void _setupAppliedRealtime() {
    // Removed the 'filter' to ensure the listener catches NEW applications
    // and STATUS updates instantly on simulators.
    _appliedChannel = Supabase.instance.client
        .channel('public:chat_requests_applied')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_requests',
          callback: (payload) {
            // Re-fetch whenever any change happens to stay in sync
            _fetchApplications();
          },
        )
        .subscribe();
  }

  Future<void> _fetchApplications() async {
    try {
      final data = await Supabase.instance.client
          .from('chat_requests')
          .select('''
            *,
            ventures(title),
            profiles!receiver_id(full_name)
          ''')
          .eq('sender_id', _currentUserId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _myApplications = data as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    Supabase.instance.client.removeChannel(_appliedChannel);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Applied Projects", 
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B3C73))
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myApplications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator( // Added for manual fallback
                  onRefresh: _fetchApplications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _myApplications.length,
                    itemBuilder: (context, index) {
                      final req = _myApplications[index];
                      final inventorName = req['profiles']?['full_name'] ?? "Founder";
                      final ventureTitle = req['ventures']?['title'] ?? "Project";
                      final bool isAccepted = req['status'] == 'accepted';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: const Color(0xFFF8FAFC),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade100),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text("${ventureTitle}_$inventorName", 
                            style: const TextStyle(fontWeight: FontWeight.bold)
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              isAccepted 
                                  ? "Accepted! Tap to start chatting." 
                                  : "Status: ${req['status'].toUpperCase()}",
                              style: TextStyle(
                                color: isAccepted ? Colors.green : Colors.orange,
                                fontWeight: isAccepted ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                          trailing: isAccepted 
                              ? const Icon(Icons.chat_bubble, color: Color(0xFF1B3C73))
                              : const Icon(Icons.hourglass_empty, color: Colors.orange),
                          onTap: isAccepted 
                              ? () => context.push('/chat/${req['id']}/$ventureTitle')
                              : () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Waiting for founder's response..."))
                                  );
                                },
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center( // Removed const to allow RefreshIndicator to work properly
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.send_rounded, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text("No applications found.", style: TextStyle(color: Colors.grey)),
          TextButton(onPressed: _fetchApplications, child: const Text("Refresh")),
        ],
      ),
    );
  }
}