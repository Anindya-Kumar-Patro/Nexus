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

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return;

  try {
    final data = await Supabase.instance.client
        .from('chat_requests')
        .select('''
          *,
          ventures(title),
          profiles!sender_id(full_name) -- The !sender_id tells Supabase WHICH link to follow
        ''')
        .eq('receiver_id', user.id)
        .order('created_at', ascending: false);

    if (mounted) {
      setState(() {
        _requests = data as List<dynamic>;
        _isLoading = false;
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }
}

  Future<void> _acceptRequest(String requestId) async {
    await Supabase.instance.client
        .from('chat_requests')
        .update({'status': 'accepted'})
        .eq('id', requestId);
    
    _fetchRequests(); // Refresh the list
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Inbox", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B3C73))),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1B3C73)),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _requests.length,
                  itemBuilder: (context, index) {
                    final req = _requests[index];
                    final isPending = req['status'] == 'pending';
                    final senderName = req['profiles']?['full_name'] ?? "Someone";
                    final ventureTitle = req['ventures']?['title'] ?? "a project";

                    return Card(
                      // FIX: Changed .bottom to .only(bottom: 16)
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16), 
                        side: BorderSide(color: Colors.grey.shade100),
                      ),
                      elevation: 0,
                      color: const Color(0xFFF8FAFC),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  senderName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B3C73)),
                                ),
                                _buildStatusBadge(req['status']),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Interested in: $ventureTitle", 
                              style: const TextStyle(fontSize: 13, color: Colors.blueGrey),
                            ),
                            const Divider(height: 24),
                            _buildAnswer("Expertise:", req['expertise'] ?? "Not provided"),
                            const SizedBox(height: 12),
                            _buildAnswer("Contribution:", req['contribution'] ?? "Not provided"),
                            const SizedBox(height: 16),
                            
                            if (isPending)
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _acceptRequest(req['id']),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF1B3C73), 
                                        foregroundColor: Colors.white, 
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: const Text("Accept & Chat"),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  TextButton(
                                    onPressed: () {}, // Optional: Add reject logic later
                                    child: const Text("Ignore", style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              )
                            else if (req['status'] == 'accepted')
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    context.push('/chat/${req['id']}/${req['ventures']['title']}');
                                  },
                                  icon: const Icon(Icons.chat_outlined),
                                  label: const Text("Open Chat"),
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mail_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text("No requests yet. Your future co-founders await!", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildAnswer(String label, String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        const SizedBox(height: 4),
        Text(text, style: const TextStyle(fontSize: 14, color: Colors.black87)),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = status == 'accepted' ? Colors.green : (status == 'pending' ? Colors.orange : Colors.grey);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }
}