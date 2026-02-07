import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../domain/venture_model.dart';

class VentureDetailScreen extends StatefulWidget {
  final Venture venture;

  const VentureDetailScreen({super.key, required this.venture});

  @override
  State<VentureDetailScreen> createState() => _VentureDetailScreenState();
}

class _VentureDetailScreenState extends State<VentureDetailScreen> {
  bool isLoadingOwner = true;
  Map<String, dynamic>? ownerProfile;
  bool isMyVenture = false;
  bool hasApplied = false; 

  @override
  void initState() {
    super.initState();
    _fetchOwnerDetails();
  }

  Future<void> _fetchOwnerDetails() async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    
    if (currentUserId == widget.venture.ownerId) {
      if (mounted) setState(() { isMyVenture = true; isLoadingOwner = false; });
      return;
    }

    // 1. Fetch Owner Profile
    final data = await Supabase.instance.client
        .from('profiles')
        .select('full_name, linkedin_url, email, department')
        .eq('id', widget.venture.ownerId)
        .maybeSingle();

    // 2. Check for existing application
    final requestCheck = await Supabase.instance.client
      .from('chat_requests')
      .select('id')
      .eq('venture_id', widget.venture.id)
      .eq('sender_id', currentUserId!)
      .maybeSingle();

    if (mounted) {
      setState(() {
        ownerProfile = data;
        hasApplied = requestCheck != null; 
        isLoadingOwner = false;
      });
    }
  }

  // Questionnaire Dialog for Nexus Chat
  void _showApplyDialog() {
    final expertiseController = TextEditingController();
    final contributionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Join Project", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B3C73))),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: expertiseController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: "What is your expertise?",
                  hintText: "e.g. Fullstack Dev, Marketing Lead",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contributionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "How will you contribute?",
                  hintText: "Briefly explain how you'd like to help...",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (expertiseController.text.isEmpty || contributionController.text.isEmpty) return;
              
              await Supabase.instance.client.from('chat_requests').insert({
                'venture_id': widget.venture.id,
                'sender_id': Supabase.instance.client.auth.currentUser!.id,
                'receiver_id': widget.venture.ownerId,
                'expertise': expertiseController.text,
                'contribution': contributionController.text,
                'status': 'pending', // Key for Real-time tracking
              });

              if (mounted) {
                setState(() => hasApplied = true); 
                context.pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Request sent! Check your 'Applied' tab."))
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B3C73)),
            child: const Text("Send Request", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _markAsFilled() async {
    await Supabase.instance.client
        .from('ventures')
        .update({'status': 'completed'})
        .eq('id', widget.venture.id);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Position marked as filled!")));
      context.go('/');
    }
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1B3C73)),
          onPressed: () => context.pop(),
        ),
        title: const Text("Venture Details", style: TextStyle(color: Color(0xFF1B3C73), fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          Positioned(
            top: 0, right: 0, left: 0, height: 400,
            child: CustomPaint(painter: HeaderGeometricPainter()),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Text(
                    widget.venture.title,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Color(0xFF003366), letterSpacing: -1.0, height: 1.2),
                  ),
                  const SizedBox(height: 12),
                  _buildStageBadge(),
                  const SizedBox(height: 24),
                  Text(
                    widget.venture.oneLiner,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.blueGrey.shade700, fontStyle: FontStyle.italic, height: 1.4),
                  ),
                  const SizedBox(height: 32),
                  const Divider(color: Color(0xFFEEEEEE), thickness: 2),
                  const SizedBox(height: 24),
                  _buildSectionHeader("About the Project"),
                  const SizedBox(height: 12),
                  Text(widget.venture.description, style: TextStyle(fontSize: 16, height: 1.6, color: Colors.grey.shade800)),
                  const SizedBox(height: 32),
                  _buildSectionHeader("Looking For"),
                  const SizedBox(height: 12),
                  _buildRolesList(),
                  const SizedBox(height: 40),

                  if (isMyVenture) ...[
                    _buildPrimaryButton(
                      label: "Edit Venture", 
                      icon: Icons.edit_outlined, 
                      onPressed: () => context.push('/create-venture', extra: widget.venture),
                    ),
                    const SizedBox(height: 12),
                    if (widget.venture.status == 'active')
                      _buildPrimaryButton(
                        label: "Mark Position Filled", 
                        icon: Icons.check_circle_outline, 
                        onPressed: _markAsFilled,
                        color: Colors.green.shade700,
                      ),
                  ] else if (isLoadingOwner)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    _buildPrimaryButton(
                      label: hasApplied ? "Applied" : "Apply via Nexus Chat", 
                      icon: hasApplied ? Icons.check_circle : Icons.chat_bubble_outline, 
                      onPressed: hasApplied ? () {} : _showApplyDialog,
                      color: hasApplied ? Colors.grey : const Color(0xFF1B3C73),
                    ),
                    const SizedBox(height: 24),
                    _buildOwnerCard(),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({required String label, required IconData icon, required VoidCallback onPressed, Color color = const Color(0xFF1B3C73)}) {
    return SizedBox(
      width: double.infinity, height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed, icon: Icon(icon), label: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      ),
    );
  }

  Widget _buildOwnerCard() {
    final email = ownerProfile?['email'];
    final linkedin = ownerProfile?['linkedin_url'];
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.blueGrey.shade100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 24, backgroundColor: const Color(0xFF1B3C73).withOpacity(0.1), child: const Icon(Icons.person, color: Color(0xFF1B3C73))),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ownerProfile?['full_name'] ?? "Unknown", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B3C73))),
                  Text(ownerProfile?['department'] ?? 'IITB', style: TextStyle(fontSize: 14, color: Colors.blueGrey.shade600)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          if (email != null) ListTile(contentPadding: EdgeInsets.zero, title: const Text("Email Me"), subtitle: Text(email), onTap: () => _launch("mailto:$email")),
          if (linkedin != null && linkedin.isNotEmpty) ListTile(contentPadding: EdgeInsets.zero, title: const Text("LinkedIn Profile"), onTap: () => _launch(linkedin)),
        ],
      ),
    );
  }

  Widget _buildStageBadge() {
    final isCompleted = widget.venture.status == 'completed';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (isCompleted ? Colors.green : const Color(0xFF0047AB)).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (isCompleted ? Colors.green : const Color(0xFF0047AB)).withOpacity(0.2)),
      ),
      child: Text(
        (isCompleted ? 'FILLED' : widget.venture.stage).toUpperCase(),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isCompleted ? Colors.green.shade700 : const Color(0xFF0047AB), letterSpacing: 1.0),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 4, height: 24, decoration: BoxDecoration(color: const Color(0xFF40E0D0), borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B3C73))),
      ],
    );
  }

  Widget _buildRolesList() {
    return Wrap(
      spacing: 10, runSpacing: 10,
      children: widget.venture.lookingFor.map((role) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
        child: Text(role, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blueGrey.shade800)),
      )).toList(),
    );
  }
}

class HeaderGeometricPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final w = size.width; final h = size.height;
    paint.color = const Color(0xFF40E0D0).withOpacity(0.04);
    final path1 = Path(); path1.moveTo(w, 0); path1.lineTo(w, h); path1.lineTo(0, 0); path1.close();
    canvas.drawPath(path1, paint);
    paint.color = const Color(0xFF0047AB).withOpacity(0.03);
    final path2 = Path(); path2.moveTo(w, 0); path2.lineTo(w, h * 0.8); path2.lineTo(w * 0.2, 0); path2.close();
    canvas.drawPath(path2, paint);
    paint.color = const Color(0xFF0047AB).withOpacity(0.06);
    final path3 = Path(); path3.moveTo(w, 0); path3.lineTo(w, h * 0.5); path3.lineTo(w * 0.6, 0); path3.close();
    canvas.drawPath(path3, paint);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}