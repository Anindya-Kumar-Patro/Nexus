import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String requestId;
  final String ventureTitle;

  const ChatScreen({super.key, required this.requestId, required this.ventureTitle});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  late RealtimeChannel _chatChannel;
  late RealtimeChannel _statusChannel;
  final String _currentUserId = Supabase.instance.client.auth.currentUser!.id;
  
  String _dynamicTitle = "";
  String? _otherUserId;
  String _requestStatus = 'pending'; // Smart Status logic
  bool _isLoadingStatus = true;

  @override
  void initState() {
    super.initState();
    _dynamicTitle = widget.ventureTitle;
    _fetchChatDetails();
    _fetchMessages();
    _setupRealtime();
    _markMessagesAsRead();
  }

  /// Fetches Chat details and initial Request Status
  Future<void> _fetchChatDetails() async {
    try {
      final data = await Supabase.instance.client
          .from('chat_requests')
          .select('''
            status,
            ventures(title),
            sender:sender_id(full_name),
            receiver:receiver_id(full_name),
            sender_id,
            receiver_id
          ''')
          .eq('id', widget.requestId)
          .single();

      final String project = data['ventures']['title'] ?? "Project";
      final String senderName = data['sender']['full_name'] ?? "Applicant";
      final String receiverName = data['receiver']['full_name'] ?? "Inventor";
      
      if (mounted) {
        setState(() {
          _requestStatus = data['status'] ?? 'pending';
          _isLoadingStatus = false;
          if (_currentUserId == data['sender_id']) {
            _dynamicTitle = "${project}_$receiverName";
            _otherUserId = data['receiver_id'];
          } else {
            _dynamicTitle = "${project}_$senderName";
            _otherUserId = data['sender_id'];
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching chat details: $e");
      if (mounted) setState(() => _isLoadingStatus = false);
    }
  }

void _setupRealtime() {
  _chatChannel = Supabase.instance.client
      .channel('chat_room:${widget.requestId}')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'request_id',
          value: widget.requestId,
        ),
        callback: (payload) {
          final newMessage = payload.newRecord;
          if (mounted) {
            setState(() {
              final index = _messages.indexWhere((m) => m['id'] == newMessage['id']);
              if (index != -1) {
                _messages[index] = newMessage;
              } else {
                _messages.insert(0, newMessage);
              }
            });
            if (newMessage['sender_id'] != _currentUserId) {
              _markMessagesAsRead();
            }
          }
        },
      )
      .subscribe();

    // 2. SMART STATUS LISTENER: Unlocks chat instantly when founder accepts
    _statusChannel = Supabase.instance.client
        .channel('status_room:${widget.requestId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'chat_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: widget.requestId,
          ),
          callback: (payload) {
            if (mounted) {
              setState(() => _requestStatus = payload.newRecord['status']);
            }
          },
        )
        .subscribe();
  }

  Future<void> _fetchMessages() async {
    final data = await Supabase.instance.client
        .from('messages')
        .select()
        .eq('request_id', widget.requestId)
        .order('created_at', ascending: false);
    
    if (mounted) {
      setState(() {
        _messages.clear();
        _messages.addAll(List<Map<String, dynamic>>.from(data));
      });
    }
  }

  Future<void> _markMessagesAsRead() async {
    await Supabase.instance.client
        .from('messages')
        .update({'status': 'read', 'is_read': true})
        .eq('request_id', widget.requestId)
        .neq('sender_id', _currentUserId);
  }

  Future<void> _sendMessage() async {
  if (_messageController.text.trim().isEmpty || _requestStatus != 'accepted') return;
  
  final content = _messageController.text.trim();
  _messageController.clear();
  
  // 1. We'll skip the manual insert 'tempId' if you want zero blink, 
  // or ensure the database insert returns the actual ID quickly.
  
  try {
    // By awaiting the insert, we get the real record back immediately
    final response = await Supabase.instance.client.from('messages').insert({
      'request_id': widget.requestId,
      'sender_id': _currentUserId,
      'receiver_id': _otherUserId,
      'content': content,
      'status': 'sent',
    }).select().single(); // .select().single() is the secret to zero blink
    
    // We don't even need to manually update setState here because 
    // the Realtime listener will catch this 'insert' and update the UI.
  } catch (e) {
    debugPrint("Send error: $e");
  }
}

  @override
  void dispose() {
    Supabase.instance.client.removeChannel(_chatChannel);
    Supabase.instance.client.removeChannel(_statusChannel);
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLocked = _requestStatus != 'accepted';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        title: Text(_dynamicTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B3C73))),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1B3C73)), onPressed: () => context.pop()),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoadingStatus 
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) => _buildMessageBubble(_messages[index], _messages[index]['sender_id'] == _currentUserId),
                  ),
          ),
          // SMART INPUT: Show keyboard only if accepted
          isLocked ? _buildLockedUI() : _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildLockedUI() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))]
      ),
      child: SafeArea(
        child: Row(
          children: [
            const Icon(Icons.lock_clock_outlined, color: Colors.orange, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Waiting for founder to accept your request...",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))]),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: "Message...",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: const Color(0xFF1B3C73),
              child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: _sendMessage),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe) {
    final DateTime createdAt = DateTime.parse(msg['created_at']).toLocal();
    final timeStr = DateFormat('jm').format(createdAt);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF1B3C73) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(msg['content'], style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 16)),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(timeStr, style: TextStyle(color: isMe ? Colors.white70 : Colors.grey, fontSize: 10)),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  _buildStatusIcon(msg['status'] ?? 'sent'),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    switch (status) {
      case 'sending': return const Icon(Icons.access_time, size: 12, color: Colors.white70);
      case 'sent': return const Icon(Icons.check, size: 12, color: Colors.white70);
      case 'delivered': return const Icon(Icons.done_all, size: 12, color: Colors.white70);
      case 'read': return const Icon(Icons.done_all, size: 12, color: Colors.lightBlueAccent);
      default: return const Icon(Icons.check, size: 12, color: Colors.white70);
    }
  }
}