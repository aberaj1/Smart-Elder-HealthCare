import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'elder_dashboard_screen.dart';
import 'caregiver_dashboard_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  bool isLoading = false;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Future<void> _selectRole(String role) async {
    final user = FirebaseAuth.instance.currentUser;

    // Check whether user is logged in
    if (user == null) {
      _showMessage('User not logged in. Please login again.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Save selected role in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'role': role,
      });

      if (!mounted) return;

      // Navigate based on selected role
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
      appBar: AppBar(
        title: const Text('Select Your Role'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.health_and_safety,
              size: 80,
              color: Colors.blue,
            ),

            const SizedBox(height: 20),

            const Text(
              'Who are you?',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Select your role to continue',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 40),

            // Elder button
            SizedBox(
              width: double.infinity,
              height: 100,
              child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () {
                        _selectRole('elder');
                      },
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.elderly,
                            size: 40,
                          ),
                          SizedBox(width: 15),
                          Text(
                            'I am an Elder',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // Caregiver button
            SizedBox(
              width: double.infinity,
              height: 100,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: isLoading
                    ? null
                    : () {
                        _selectRole('caregiver');
                      },
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.health_and_safety,
                            size: 40,
                          ),
                          SizedBox(width: 15),
                          Text(
                            'I am a Caregiver',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}