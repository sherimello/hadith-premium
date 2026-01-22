import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
      title: "Reset Password",
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
      textConfirm: "Send OTP",
      textCancel: "Cancel",
      onConfirm: () async {
        if (resetEmailController.text.isNotEmpty) {
          final email = resetEmailController.text.trim();
          Get.back(); // Close email dialog

          final success = await _authController.sendPasswordReset(email);
          if (success) {
            _showResetOtpDialog(email);
          }
        }
      },
    );
  }

  void _showResetOtpDialog(String email) {
    final otpController = TextEditingController();
    final newPasswordController = TextEditingController();

    Get.defaultDialog(
      title: "Enter OTP & New Password",
      content: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(
              "We sent a code to $email",
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: otpController,
              decoration: const InputDecoration(
                labelText: "6-Digit Code",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(
                labelText: "New Password",
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
      ),
      textConfirm: "Verify & Update",
      textCancel: "Cancel",
      onConfirm: () async {
        if (otpController.text.isNotEmpty &&
            newPasswordController.text.isNotEmpty) {
          final otp = otpController.text.trim();
          final newPass = newPasswordController.text.trim();

          // Close dialog first to avoid context issues or stacking
          Get.back();

          final verified = await _authController.verifyOtp(
            email: email,
            token: otp,
            type: OtpType.recovery, // Requires supabase_flutter import
          );

          if (verified) {
            final updated = await _authController.updatePassword(newPass);
            if (updated) {
              Get.offAll(() => const HomeScreen());
            }
          }
        }
      },
    );
  }

  void _showSignupOtpDialog(String email) {
    final otpController = TextEditingController();
    Get.defaultDialog(
      title: "Verify Email",
      content: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(
              "Enter the code sent to $email",
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: otpController,
              decoration: const InputDecoration(
                labelText: "6-Digit Code",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      textConfirm: "Verify",
      textCancel: "Cancel",
      onConfirm: () async {
        if (otpController.text.isNotEmpty) {
          final otp = otpController.text.trim();
          Get.back();

          final success = await _authController.verifyOtp(
            email: email,
            token: otp,
            type: OtpType.signup,
          );

          if (success) {
            Get.offAll(() => const HomeScreen());
          }
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
                            if (success) {
                              _showSignupOtpDialog(
                                _emailController.text.trim(),
                              );
                            }
                          } else {
                            success = await _authController.signIn(
                              _emailController.text.trim(),
                              _passwordController.text.trim(),
                            );
                            if (success) {
                              Get.offAll(() => const HomeScreen());
                            }
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
