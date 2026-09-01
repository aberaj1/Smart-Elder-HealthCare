import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'role_selection_screen.dart';
import 'register_screen.dart';
import 'elder_dashboard_screen.dart';
import 'caregiver_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please enter both email and password.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Step 1: Firebase Authentication Login
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;

      if (user == null) {
        throw Exception('User login failed.');
      }

      // Step 2: Get user details from Firestore
      final DocumentSnapshot userDocument =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (!mounted) return;

      // Step 3: Check role
      String? role;

      if (userDocument.exists) {
        final data = userDocument.data() as Map<String, dynamic>;
        role = data['role'];
      }

      // Step 4: Navigate according to role

      if (role == 'elder') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ElderDashboardScreen(),
          ),
        );
      } else if (role == 'caregiver') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const CaregiverDashboardScreen(),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const RoleSelectionScreen(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;

      if (e.code == 'user-not-found') {
        message = 'No account found with this email.';
      } else if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        message = 'Incorrect email or password.';
      } else if (e.code == 'invalid-email') {
        message = 'Please enter a valid email address.';
      } else if (e.code == 'user-disabled') {
        message = 'This account has been disabled.';
      } else {
        message = 'Login failed: ${e.message}';
      }

      if (mounted) {
        _showMessage(message);
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        _showMessage('Database error: ${e.message}');
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Something went wrong: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text('Smart Elder Healthcare'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.health_and_safety,
                  size: 90,
                  color: Colors.blue,
                ),

                const SizedBox(height: 20),

                const Text(
                  'Welcome',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Login to continue',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 30),

                // Email Field
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                ),

                const SizedBox(height: 20),

                // Password Field
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  enabled: !isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),

                const SizedBox(height: 30),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _login,
                    child: isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 15),

                // Register Button
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const RegisterScreen(),
                            ),
                          );
                        },
                  child: const Text(
                    'Create New Account',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}