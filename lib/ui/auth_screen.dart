import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();

  bool _isSignUp = false;

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController();
    Get.defaultDialog(
      title: "Forgot Password",
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: TextField(
          controller: resetEmailController,
          decoration: const InputDecoration(
            labelText: "Email address",
            prefixIcon: Icon(Icons.email_outlined),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
      ),
      textConfirm: "Send Link",
      textCancel: "Cancel",
      onConfirm: () {
        if (resetEmailController.text.isNotEmpty) {
          _authController.sendPasswordReset(resetEmailController.text.trim());
          Get.back();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/icon.png', width: 80, height: 80),
              const SizedBox(height: 16),
              Text(
                "Hadith Premium",
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),

              if (_isSignUp)
                TextField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: "Full Name",
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
              if (_isSignUp) const SizedBox(height: 16),

              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: "Password",
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),

              if (!_isSignUp)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgotPasswordDialog,
                    child: const Text("Forgot Password?"),
                  ),
                ),

              const SizedBox(height: 24),

              Obx(
                () => _authController.isLoading.value
                    ? const CircularProgressIndicator.adaptive()
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          bool success = false;
                          if (_isSignUp) {
                            if (_fullNameController.text.isEmpty) {
                              Get.snackbar(
                                "Error",
                                "Please enter your full name",
                              );
                              return;
                            }
                            success = await _authController.signUp(
                              email: _emailController.text.trim(),
                              password: _passwordController.text.trim(),
                              fullName: _fullNameController.text.trim(),
                            );
                          } else {
                            success = await _authController.signIn(
                              _emailController.text.trim(),
                              _passwordController.text.trim(),
                            );
                          }

                          if (success) {
                            Get.offAll(() => const HomeScreen());
                          }
                        },
                        child: Text(_isSignUp ? "Create Account" : "Sign In"),
                      ),
              ),

              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _isSignUp = !_isSignUp),
                child: Text(
                  _isSignUp
                      ? "Already have an account? Sign In"
                      : "Don't have an account? Sign Up",
                ),
              ),

              if (_isSignUp)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    "Note: A unique 5-digit username will be generated for you.",
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
