import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../ventures/domain/venture_model.dart';
import '../application/saved_provider.dart';

class VentureCard extends ConsumerWidget {
  final Venture venture;

  const VentureCard({super.key, required this.venture});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isMine = currentUserId == venture.ownerId;
    
    // FIX: Ensure we compare Strings (UUIDs)
    final savedIds = ref.watch(savedIdsProvider);
    final isSaved = savedIds.contains(venture.id.toString());

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // --- LAYER 1: Solid White Background ---
            Container(color: Colors.white),

            // --- LAYER 2: Geometric Texture ---
            Positioned.fill(
              child: CustomPaint(
                painter: ModernGeometricPainter(),
              ),
            ),

            // --- LAYER 3: Content ---
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push('/venture-detail', extra: venture),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- HEADER ROW ---
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  venture.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF003366),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  venture.oneLiner,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blueGrey.shade700,
                                    height: 1.4,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (isMine)
                            _buildBadge(
                              text: "YOU",
                              icon: Icons.person,
                              color: Colors.orange.shade900,
                              bg: Colors.orange.shade50,
                            )
                          else
                            _buildBadge(
                              text: venture.stage,
                              color: const Color(0xFF0047AB),
                              bg: Colors.blue.shade50.withOpacity(0.5),
                            ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // --- FOOTER: ROLES + FAVORITE BUTTON ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: _buildRolesList(),
                          ),
                          
                          if (!isMine)
                            IconButton(
                              onPressed: () {
                                // FIX: Explicitly convert ID to String for the toggleSave method
                                ref.read(savedIdsProvider.notifier).toggleSave(venture.id.toString());
                              },
                              icon: Icon(
                                isSaved ? Icons.favorite : Icons.favorite_border,
                                color: isSaved ? Colors.red : Colors.grey.shade400,
                                size: 28,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRolesList() {
    final roles = venture.lookingFor;
    if (roles.isEmpty) return const SizedBox.shrink();

    final shouldLimit = roles.length > 3;
    final displayRoles = shouldLimit ? roles.take(2).toList() : roles;
    final remainingCount = roles.length - 2;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...displayRoles.map((role) => _buildChip(role)),
        if (shouldLimit)
          _buildMoreChip("+$remainingCount"), 
      ],
    );
  }

  Widget _buildChip(String label) {
    final text = label.length > 18 ? "${label.substring(0, 16)}..." : label;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.blueGrey.shade700,
        ),
      ),
    );
  }

  Widget _buildMoreChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade800,
        ),
      ),
    );
  }

  Widget _buildBadge({required String text, IconData? icon, required Color color, required Color bg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: color), const SizedBox(width: 4)],
          Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class ModernGeometricPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;

    paint.color = const Color(0xFF40E0D0).withOpacity(0.05); 
    final path1 = Path();
    path1.moveTo(w, h); 
    path1.lineTo(w * 0.3, h); 
    path1.lineTo(w, h * 0.1); 
    path1.close();
    canvas.drawPath(path1, paint);

    paint.color = const Color(0xFF0047AB).withOpacity(0.04); 
    final path2 = Path();
    path2.moveTo(w, h);
    path2.lineTo(w * 0.5, h);
    path2.lineTo(w, h * 0.4);
    path2.close();
    canvas.drawPath(path2, paint);

    paint.color = const Color(0xFF0047AB).withOpacity(0.08); 
    final path3 = Path();
    path3.moveTo(w, h);
    path3.lineTo(w * 0.8, h);
    path3.lineTo(w, h * 0.8);
    path3.close();
    canvas.drawPath(path3, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}