import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final AuthService _auth = AuthService();

  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),

            const SizedBox(height: 30),

            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);

                      final name = nameController.text.trim();
                      final email = emailController.text.trim();
                      final password = passwordController.text.trim();

                      if (name.isEmpty || email.isEmpty || password.isEmpty) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text("Please fill in all fields")),
                        );
                        return;
                      }

                      setState(() => loading = true);

                      try {
                        final result =
                            await _auth.registerUser(name, email, password);

                        if (!mounted) return;

                        if (result == null) {
                          navigator.pushReplacement(
                            MaterialPageRoute(builder: (_) => const HomePage()),
                          );
                        } else {
                          messenger.showSnackBar(SnackBar(content: Text(result)));
                        }
                      } catch (e) {
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(content: Text("Sign up failed: $e")),
                        );
                      } finally {
                        if (mounted) {
                          setState(() => loading = false);
                        }
                      }
                    },
                    child: const Text("Sign Up"),
                  ),
          ],
        ),
      ),
    );
  }
}
