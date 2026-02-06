import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../application/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Toggle between Login and Sign Up mode
  bool isLoginMode = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the controller state (to show loading spinners)
    final state = ref.watch(authControllerProvider);

    // Listen for changes (Success or Error)
    ref.listen(authControllerProvider, (previous, next) {
      // 1. If Success -> Go Straight to Home
      if (!next.isLoading && !next.hasError) {
        // We go to /home. 
        // The HomeScreen will handle the profile check silently.
        context.go('/home'); 
      }
      
      // 2. If Error -> Show Red Bar
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()), 
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo / Icon
              const Icon(Icons.rocket_launch, size: 64, color: Color(0xFF1B3C73)),
              const SizedBox(height: 16),
              
              // App Name
              const Text(
                "Nexus IITB",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1B3C73)),
              ),
              const SizedBox(height: 8),
              
              // Subtitle
              Text(
                isLoginMode ? "Welcome Back, Innovator" : "Join the Ecosystem",
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 48),

              // Email Input
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "IITB Email",
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              // Password Input
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // Action Button (Login / Sign Up)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: state.isLoading
                      ? null
                      : () {
                          final email = _emailController.text.trim();
                          final password = _passwordController.text.trim();
                          
                          // Basic Validation
                          if (email.isEmpty || password.isEmpty) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text("Please fill in all fields")),
                             );
                             return;
                          }

                          if (isLoginMode) {
                            ref.read(authControllerProvider.notifier).login(email: email, password: password);
                          } else {
                            ref.read(authControllerProvider.notifier).signUp(email: email, password: password);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B3C73),
                    foregroundColor: Colors.white,
                  ),
                  child: state.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(isLoginMode ? "Log In" : "Sign Up"),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Toggle Button
              TextButton(
                onPressed: () {
                  setState(() {
                    isLoginMode = !isLoginMode;
                  });
                },
                child: Text(isLoginMode ? "New here? Create Account" : "Already have an account? Log In"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}