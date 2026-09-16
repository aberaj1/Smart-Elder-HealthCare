import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CaregiverElderLinkScreen extends StatefulWidget {
  const CaregiverElderLinkScreen({super.key});

  @override
  State<CaregiverElderLinkScreen> createState() =>
      _CaregiverElderLinkScreenState();
}

class _CaregiverElderLinkScreenState
    extends State<CaregiverElderLinkScreen> {
  final TextEditingController linkCodeController =
      TextEditingController();

  bool isLoading = true;

  String? userRole;
  String? generatedCode;

  String? linkedElderName;
  String? linkedElderEmail;

  User? get currentUser => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    loadUserLinkData();
  }

  @override
  void dispose() {
    linkCodeController.dispose();
    super.dispose();
  }

  // ================= LOAD USER DATA =================

  Future<void> loadUserLinkData() async {
    if (currentUser == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (!doc.exists) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final data = doc.data();

      if (data == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final role = data['role'];

      setState(() {
        userRole = role;
        generatedCode = data['elderLinkCode'];
      });

      // Caregiver already linked with an elder
      if (role == 'caregiver') {
        final elderId = data['elderId'];

        if (elderId != null) {
          await loadElderDetails(elderId);
        }
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      showMessage('Unable to load account information.');
    }
  }

  // ================= LOAD ELDER DETAILS =================

  Future<void> loadElderDetails(String elderId) async {
    try {
      final elderDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(elderId)
          .get();

      if (!elderDoc.exists) return;

      final data = elderDoc.data();

      if (data == null) return;

      setState(() {
        linkedElderName = data['name'];
        linkedElderEmail = data['email'];
      });
    } catch (e) {
      // Ignore loading error
    }
  }

  // ================= GENERATE CODE =================

  String generateCode() {
    final random = Random();

    return List.generate(
      6,
      (_) => random.nextInt(10),
    ).join();
  }

  Future<void> generateElderCode() async {
    if (currentUser == null) {
      showMessage('Please login first.');
      return;
    }

    // Only elder can generate code
    if (userRole != 'elder') {
      showMessage('Only elder can generate a link code.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final code = generateCode();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .set(
        {
          'elderLinkCode': code,
          'role': 'elder',
        },
        SetOptions(merge: true),
      );

      setState(() {
        generatedCode = code;
        isLoading = false;
      });

      showMessage('Link code generated successfully!');
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      showMessage('Error generating link code.');
    }
  }

  // ================= LINK ELDER =================

  Future<void> linkElder() async {
    if (currentUser == null) {
      showMessage('Please login first.');
      return;
    }

    // Only caregiver can enter code
    if (userRole != 'caregiver') {
      showMessage('Only caregiver can link an elder.');
      return;
    }

    final code = linkCodeController.text.trim();

    if (code.length != 6) {
      showMessage('Enter a valid 6-digit link code.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final result = await FirebaseFirestore.instance
          .collection('users')
          .where(
            'elderLinkCode',
            isEqualTo: code,
          )
          .where(
            'role',
            isEqualTo: 'elder',
          )
          .limit(1)
          .get();

      if (result.docs.isEmpty) {
        setState(() {
          isLoading = false;
        });

        showMessage('Invalid link code.');
        return;
      }

      final elderDoc = result.docs.first;

      final elderId = elderDoc.id;
      final elderData = elderDoc.data();

      // Prevent self-link
      if (elderId == currentUser!.uid) {
        setState(() {
          isLoading = false;
        });

        showMessage('You cannot link your own account.');
        return;
      }

      // Check whether elder is already linked
      final existingCaregiverId = elderData['caregiverId'];

      if (existingCaregiverId != null &&
          existingCaregiverId != currentUser!.uid) {
        setState(() {
          isLoading = false;
        });

        showMessage('This elder is already linked with another caregiver.');
        return;
      }

      // Save elder ID inside caregiver document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .set(
        {
          'elderId': elderId,
          'role': 'caregiver',
        },
        SetOptions(merge: true),
      );

      // Save caregiver ID inside elder document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(elderId)
          .set(
        {
          'caregiverId': currentUser!.uid,
        },
        SetOptions(merge: true),
      );

      setState(() {
        linkedElderName = elderData['name'];
        linkedElderEmail = elderData['email'];
        isLoading = false;
      });

      linkCodeController.clear();

      showMessage('Elder linked successfully!');
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      showMessage('Error linking elder: $e');
    }
  }

  // ================= UNLINK =================

  Future<void> unlinkElder() async {
    if (currentUser == null) return;

    if (linkedElderName == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Unlink Elder'),
          content: Text(
            'Do you want to unlink $linkedElderName?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Unlink'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      isLoading = true;
    });

    try {
      final caregiverDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      final caregiverData = caregiverDoc.data();

      final elderId = caregiverData?['elderId'];

      // Remove caregiver from elder
      if (elderId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(elderId)
            .set(
          {
            'caregiverId': FieldValue.delete(),
          },
          SetOptions(merge: true),
        );
      }

      // Remove elder from caregiver
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .set(
        {
          'elderId': FieldValue.delete(),
        },
        SetOptions(merge: true),
      );

      setState(() {
        linkedElderName = null;
        linkedElderEmail = null;
        isLoading = false;
      });

      showMessage('Elder unlinked successfully.');
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      showMessage('Unable to unlink elder.');
    }
  }

  // ================= MESSAGE =================

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ================= ELDER SECTION =================

  Widget buildElderSection() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.person,
                  color: Colors.green,
                  size: 30,
                ),
                SizedBox(width: 10),
                Text(
                  'Elder Link Code',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            const Text(
              'Generate this code and share it with your caregiver.',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 18),

            if (generatedCode != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green,
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'YOUR LINK CODE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      generatedCode!,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 6,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    isLoading ? null : generateElderCode,
                icon: const Icon(Icons.refresh),
                label: Text(
                  generatedCode == null
                      ? 'Generate Link Code'
                      : 'Generate New Code',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= CAREGIVER SECTION =================

  Widget buildCaregiverSection() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.supervisor_account,
                  color: Colors.blue,
                  size: 30,
                ),
                SizedBox(width: 10),
                Text(
                  'Link an Elder',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            const Text(
              'Enter the 6-digit code provided by the elder.',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 18),

            TextField(
              controller: linkCodeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Elder Link Code',
                hintText: 'Example: 123456',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
                counterText: '',
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    isLoading ? null : linkElder,
                icon: const Icon(Icons.link),
                label: const Text(
                  'Link Elder',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= LINKED ELDER =================

  Widget buildLinkedElder() {
    if (linkedElderName == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 3,
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const Icon(
              Icons.verified_user,
              color: Colors.green,
              size: 55,
            ),

            const SizedBox(height: 10),

            const Text(
              'Elder Linked Successfully',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.person),
              ),
              title: Text(
                linkedElderName!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                linkedElderEmail ?? '',
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed:
                    isLoading ? null : unlinkElder,
                icon: const Icon(
                  Icons.link_off,
                  color: Colors.red,
                ),
                label: const Text(
                  'Unlink Elder',
                  style: TextStyle(
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Caregiver - Elder Link'),
        ),
        body: const Center(
          child: Text('Please login first.'),
        ),
      );
    }

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Caregiver & Elder Link',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // ================= ELDER UI =================

    if (userRole == 'elder') {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Elder Link',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(
                Icons.person,
                size: 75,
                color: Colors.green,
              ),

              const SizedBox(height: 10),

              const Text(
                'Connect with Caregiver',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              const Text(
                'Generate a code and share it with your caregiver.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 25),

              buildElderSection(),
            ],
          ),
        ),
      );
    }

    // ================= CAREGIVER UI =================

    if (userRole == 'caregiver') {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Caregiver - Elder Link',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(
                Icons.supervisor_account,
                size: 75,
                color: Colors.blue,
              ),

              const SizedBox(height: 10),

              const Text(
                'Connect with Elder',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              const Text(
                'Enter the link code provided by the elder.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 25),

              // Show code input only if not linked
              if (linkedElderName == null)
                buildCaregiverSection(),

              if (linkedElderName != null)
                buildLinkedElder(),
            ],
          ),
        ),
      );
    }

    // ================= UNKNOWN ROLE =================

    return Scaffold(
      appBar: AppBar(
        title: const Text('Elder & Caregiver Link'),
      ),
      body: const Center(
        child: Text(
          'Role not selected. Please select your role first.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}