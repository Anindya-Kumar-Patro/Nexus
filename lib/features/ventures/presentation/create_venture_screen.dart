import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/create_venture_controller.dart';
import '../application/feed_controller.dart';
import '../domain/venture_model.dart';

class CreateVentureScreen extends ConsumerStatefulWidget {
  final Venture? ventureToEdit;

  const CreateVentureScreen({super.key, this.ventureToEdit});

  @override
  ConsumerState<CreateVentureScreen> createState() => _CreateVentureScreenState();
}

class _CreateVentureScreenState extends ConsumerState<CreateVentureScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController _titleController;
  late TextEditingController _oneLinerController;
  late TextEditingController _descController;
  final _customRoleController = TextEditingController(); // <--- NEW

  String selectedStage = 'Brainstorming';
  final stages = ['Brainstorming', 'MVP', 'Early Traction', 'Funded'];
  
  // This list now holds EVERYTHING (Standard + Custom)
  List<String> _selectedRoles = [];
  
  // These are just suggestions
  final suggestedRoles = [
    'Co-founder', 'Tech Lead', 'React Dev', 'App Dev', 
    'Designer', 'Marketing', 'Video Editor', 'Legal', 'Sales'
  ];

  @override
  void initState() {
    super.initState();
    final v = widget.ventureToEdit;

    _titleController = TextEditingController(text: v?.title ?? '');
    _oneLinerController = TextEditingController(text: v?.oneLiner ?? '');
    _descController = TextEditingController(text: v?.description ?? '');
    
    if (v != null) {
      if (stages.contains(v.stage)) selectedStage = v.stage;
      _selectedRoles = List.from(v.lookingFor);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _oneLinerController.dispose();
    _descController.dispose();
    _customRoleController.dispose();
    super.dispose();
  }

  // --- LOGIC: Add a Custom Role ---
  void _addCustomRole() {
    final text = _customRoleController.text.trim();
    if (text.isNotEmpty && !_selectedRoles.contains(text)) {
      setState(() {
        _selectedRoles.add(text);
        _customRoleController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createVentureControllerProvider);
    final isEditing = widget.ventureToEdit != null;

    ref.listen(createVentureControllerProvider, (previous, next) {
      if (!next.isLoading && !next.hasError) {
        ref.invalidate(feedControllerProvider); // Refresh Home
        ref.invalidate(myVenturesProvider);     // Refresh "My Ventures" too!
        
        context.go('/home'); 
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? "Venture Updated! ✅" : "Venture Launched! 🚀"),
            backgroundColor: Colors.green,
          ),
        );
      }

      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${next.error}"), 
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Edit Venture" : "Post New Venture"),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Venture Name", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _oneLinerController,
                maxLength: 60,
                decoration: const InputDecoration(labelText: "One Liner", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: "Detailed Description", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField(
                value: selectedStage,
                decoration: const InputDecoration(labelText: "Current Stage", border: OutlineInputBorder()),
                items: stages.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => setState(() => selectedStage = val!),
              ),
              const SizedBox(height: 24),
              
              // --- UPGRADED ROLES SECTION ---
              const Text("Who do you need?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),

              // 1. INPUT FIELD (Custom)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customRoleController,
                      decoration: const InputDecoration(
                        hintText: "Add custom role (e.g. Drone Pilot)",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      ),
                      onSubmitted: (_) => _addCustomRole(), // Allow Enter key
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addCustomRole,
                    icon: const Icon(Icons.add_circle, color: Color(0xFF1B3C73), size: 32),
                  )
                ],
              ),
              const SizedBox(height: 12),

              // 2. SELECTED ROLES (Chips with Delete 'X')
              if (_selectedRoles.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedRoles.map((role) {
                    return Chip(
                      label: Text(role, style: const TextStyle(color: Colors.white)),
                      backgroundColor: const Color(0xFF1B3C73),
                      deleteIcon: const Icon(Icons.close, size: 18, color: Colors.white),
                      onDeleted: () {
                        setState(() {
                          _selectedRoles.remove(role);
                        });
                      },
                    );
                  }).toList(),
                ),
              
              const SizedBox(height: 16),
              const Text("Quick Add:", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),

              // 3. SUGGESTIONS (Click to Add)
              Wrap(
                spacing: 8,
                children: suggestedRoles.where((r) => !_selectedRoles.contains(r)).map((role) {
                  return ActionChip(
                    label: Text(role),
                    onPressed: () {
                      setState(() {
                        _selectedRoles.add(role);
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B3C73), foregroundColor: Colors.white),
                  onPressed: state.isLoading ? null : _submit,
                  child: state.isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : Text(isEditing ? "Update Venture" : "Launch Venture 🚀"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Logic for Update vs Create
      if (widget.ventureToEdit != null) {
        ref.read(createVentureControllerProvider.notifier).updateVenture(
          ventureId: widget.ventureToEdit!.id,
          title: _titleController.text.trim(),
          oneLiner: _oneLinerController.text.trim(),
          description: _descController.text.trim(),
          stage: selectedStage,
          lookingFor: _selectedRoles,
        );
      } else {
        ref.read(createVentureControllerProvider.notifier).postVenture(
          title: _titleController.text.trim(),
          oneLiner: _oneLinerController.text.trim(),
          description: _descController.text.trim(),
          stage: selectedStage,
          lookingFor: _selectedRoles,
        );
      }
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Venture?"),
        content: const Text("This cannot be undone."),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              context.pop();
              ref.read(createVentureControllerProvider.notifier)
                 .deleteVenture(widget.ventureToEdit!.id);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}