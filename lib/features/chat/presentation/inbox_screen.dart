import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  bool _isLoading = true;
  List<dynamic> _requests = [];
  final String _currentUserId = Supabase.instance.client.auth.currentUser!.id;
  late RealtimeChannel _inboxChannel;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
    _setupInboxRealtime();
  }

  // 1. IMPROVED REALTIME: Listens for ANY change (INSERT, UPDATE, DELETE)
  void _setupInboxRealtime() {
    _inboxChannel = Supabase.instance.client
        .channel('public:chat_requests_inbox')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_requests',
          callback: (payload) {
            debugPrint("Realtime Update Received: ${payload.toString()}");
            _fetchRequests();
          },
        )
        .subscribe();
  }

  // 2. ROBUST FETCH: Explicitly filters where YOU are the project owner
  Future<void> _fetchRequests() async {
    try {
      final data = await Supabase.instance.client
          .from('chat_requests')
          .select('''
            *,
            ventures(title),
            profiles!sender_id(full_name)
          ''')
          .eq('receiver_id', _currentUserId) // Ensures you only see requests sent TO you
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _requests = data as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading inbox: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    Supabase.instance.client.removeChannel(_inboxChannel);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Received Requests", 
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B3C73))),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchRequests,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _requests.length,
                    itemBuilder: (context, index) {
                      final req = _requests[index];
                      final senderName = req['profiles']?['full_name'] ?? "User";
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
                          title: Text("${ventureTitle}_$senderName", 
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(isAccepted ? "Tap to chat" : "New application - tap to view"),
                          trailing: isAccepted 
                              ? const Icon(Icons.chat, color: Color(0xFF1B3C73))
                              : const Icon(Icons.notification_important, color: Colors.orange),
                          onTap: () {
                            if (isAccepted) {
                              context.push('/chat/${req['id']}/$ventureTitle');
                            } else {
                              _showAcceptDialog(req['id'], senderName);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  void _showAcceptDialog(String requestId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Request from $name"),
        content: const Text("Would you like to accept this application and start a chat?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Review")),
          ElevatedButton(
            onPressed: () async {
              await Supabase.instance.client
                  .from('chat_requests')
                  .update({'status': 'accepted'})
                  .eq('id', requestId);
              Navigator.pop(context);
              _fetchRequests();
            },
            child: const Text("Accept"),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text("No incoming requests found.", style: TextStyle(color: Colors.grey)),
          TextButton(onPressed: _fetchRequests, child: const Text("Refresh")),
        ],
      ),
    );
  }
}