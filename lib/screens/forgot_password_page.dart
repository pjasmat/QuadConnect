import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/error_messages.dart';
import '../utils/validation.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final emailController = TextEditingController();
  final AuthService _auth = AuthService();
  bool loading = false;
  bool emailSent = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reset Password")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!emailSent) ...[
              const Icon(Icons.lock_reset, size: 64, color: Colors.blue),
              const SizedBox(height: 24),
              const Text(
                "Forgot Password?",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                "Enter your email address and we'll send you a link to reset your password.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                enabled: !loading,
              ),
              const SizedBox(height: 24),
              loading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final email = emailController.text.trim();

                          if (email.isEmpty) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Please enter your email address",
                                ),
                              ),
                            );
                            return;
                          }

                          if (!Validation.isValidEmail(email)) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Please enter a valid email address",
                                ),
                              ),
                            );
                            return;
                          }

                          setState(() => loading = true);

                          try {
                            final result = await _auth.resetPassword(email);

                            if (!mounted) return;

                            if (result == null) {
                              setState(() {
                                loading = false;
                                emailSent = true;
                              });
                            } else {
                              setState(() => loading = false);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    ErrorMessages.getUserFriendlyError(result),
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } catch (e) {
                            if (!mounted) return;
                            setState(() => loading = false);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  ErrorMessages.getUserFriendlyError(e),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: const Text("Send Reset Link"),
                      ),
                    ),
            ] else ...[
              const Icon(Icons.check_circle, size: 64, color: Colors.green),
              const SizedBox(height: 24),
              const Text(
                "Email Sent!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                "We've sent a password reset link to ${emailController.text.trim()}",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                "Please check your email and follow the instructions to reset your password.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Back to Login"),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
