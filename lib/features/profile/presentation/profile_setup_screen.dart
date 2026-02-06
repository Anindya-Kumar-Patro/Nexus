import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../application/profile_controller.dart';
import '../../auth/application/auth_controller.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _rollController = TextEditingController();
  final _linkedinController = TextEditingController();
  
  // Dropdown Defaults
  String selectedDept = 'SJMSOM'; 
  String selectedRole = 'Founder'; 

  final departments = ['SJMSOM', 'CSE', 'Electrical', 'Mechanical', 'Civil', 'Aerospace', 'Other'];
  final roles = ['Founder', 'Builder (Dev/Design)', 'Both'];

  bool isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // --- NEW: FETCH EXISTING DATA ---
  Future<void> _loadUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        // If data exists, pre-fill the form!
        setState(() {
          _nameController.text = data['full_name'] ?? '';
          _rollController.text = data['roll_number'] ?? '';
          _linkedinController.text = data['linkedin_url'] ?? '';
          
          if (departments.contains(data['department'])) {
            selectedDept = data['department'];
          }
          if (roles.contains(data['role'])) {
            selectedRole = data['role'];
          }
        });
      }
    } catch (e) {
      // If error, just stay blank (treat as new user)
      debugPrint("Error loading profile: $e");
    } finally {
      setState(() => isLoadingData = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);

    ref.listen(profileControllerProvider, (previous, next) {
      if (!next.isLoading && !next.hasError) {
        // On Success -> Go Home
        context.go('/home');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Saved! ✅")),
        );
      }
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${next.error}"), backgroundColor: Colors.red),
        );
      }
    });

    if (isLoadingData) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Your Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Edit Your Identity", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const Text("Keep your info up to date."),
              const SizedBox(height: 30),

              // Full Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),

              // Roll Number
              TextFormField(
                controller: _rollController,
                decoration: const InputDecoration(labelText: "Roll Number", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),

              // Department
              DropdownButtonFormField(
                value: selectedDept,
                decoration: const InputDecoration(labelText: "Department", border: OutlineInputBorder()),
                items: departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (val) => setState(() => selectedDept = val!),
              ),
              const SizedBox(height: 16),

              // Role
              DropdownButtonFormField(
                value: selectedRole,
                decoration: const InputDecoration(labelText: "Primary Role", border: OutlineInputBorder()),
                items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (val) => setState(() => selectedRole = val!),
              ),
              const SizedBox(height: 16),
              
              // LinkedIn
              TextFormField(
                controller: _linkedinController,
                decoration: const InputDecoration(labelText: "LinkedIn URL (Optional)", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B3C73), foregroundColor: Colors.white),
                  onPressed: state.isLoading ? null : _submit,
                  child: state.isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("Save Changes"),
                ),
              ),
              
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),

              // Sign Out Button
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                     ref.read(authControllerProvider.notifier).logout();
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text("Sign Out", style: TextStyle(color: Colors.red)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ref.read(profileControllerProvider.notifier).updateProfile(
        fullName: _nameController.text.trim(),
        rollNumber: _rollController.text.trim(),
        department: selectedDept,
        role: selectedRole,
        linkedin: _linkedinController.text.trim(),
      );
    }
  }
}