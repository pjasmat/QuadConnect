import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'signup_page.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthService _auth = AuthService();

  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("QuadConnect",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),

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

                      final email = emailController.text.trim();
                      final password = passwordController.text.trim();

                      if (email.isEmpty || password.isEmpty) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text("Please enter email and password")),
                        );
                        return;
                      }

                      setState(() => loading = true);

                      try {
                        final result = await _auth.loginUser(email, password);

                        if (!mounted) return;

                        if (result == null) {
                          navigator.pushReplacement(
                              MaterialPageRoute(builder: (_) => const HomePage()));
                        } else {
                          messenger.showSnackBar(SnackBar(content: Text(result)));
                        }
                      } catch (e) {
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(content: Text("Login failed: $e")),
                        );
                      } finally {
                        if (mounted) {
                          setState(() => loading = false);
                        }
                      }
                    },
                    child: const Text("Login"),
                  ),

            const SizedBox(height: 15),

            TextButton(
              onPressed: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const SignupPage()));
              },
              child: const Text("Create an account"),
            ),
          ],
        ),
      ),
    );
  }
}
