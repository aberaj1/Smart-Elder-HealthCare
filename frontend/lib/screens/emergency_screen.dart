
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  bool isSaving = false;
  bool isSendingSOS = false;

  final Color redColor = const Color(0xFFE53935);
  final Color greenColor = const Color(0xFF2EAD62);

  User? get currentUser => FirebaseAuth.instance.currentUser;

  DocumentReference<Map<String, dynamic>> get contactRef {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('emergency_contacts')
        .doc('primary');
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> saveContact() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      showMessage('Enter contact name and phone number');
      return;
    }

    if (phone.length < 10) {
      showMessage('Enter a valid phone number');
      return;
    }

    if (currentUser == null) {
      showMessage('Please login first');
      return;
    }

    setState(() => isSaving = true);

    try {
      await contactRef.set({
        'name': name,
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
      });

      nameController.clear();
      phoneController.clear();

      showMessage('Emergency contact saved');
    } catch (e) {
      showMessage('Unable to save contact');
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> deleteContact() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact?'),
        content: const Text(
          'Are you sure you want to delete this emergency contact?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await contactRef.delete();
        showMessage('Contact deleted');
      } catch (e) {
        showMessage('Unable to delete contact');
      }
    }
  }

  Future<void> callContact(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);

    try {
      final launched = await launchUrl(uri);

      if (!launched) {
        showMessage('Unable to open phone dialer');
      }
    } catch (e) {
      showMessage('Unable to open phone dialer');
    }
  }

  Future<void> sendSOS() async {
    if (currentUser == null) {
      showMessage('Please login first');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'EMERGENCY SOS',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Do you want to send an emergency alert to your caregiver?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SEND SOS'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isSendingSOS = true);

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      final userData = userDoc.data() ?? {};
      final elderName =
          userData['name'] ?? userData['fullName'] ?? 'Elder';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('sos_alerts')
          .add({
        'elderId': currentUser!.uid,
        'elderName': elderName,
        'message': 'Emergency SOS activated by $elderName',
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });

      showMessage('SOS alert sent successfully');
    } catch (e) {
      showMessage('Failed to send SOS. Please try again.');
    } finally {
      if (mounted) setState(() => isSendingSOS = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please login first')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        title: const Text(
          'Emergency',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // Add emergency contact
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Emergency Contact',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: 'Contact name',
                      prefixIcon: const Icon(Icons.person_outline),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Phone number',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : saveContact,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF344D9A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'SAVE CONTACT',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Saved contact
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: contactRef.snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Text('Unable to load contact');
                      }

                      if (!snapshot.hasData ||
                          !snapshot.data!.exists) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'No saved contact yet',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      final data = snapshot.data!.data()!;
                      final name = data['name']?.toString() ?? '';
                      final phone = data['phone']?.toString() ?? '';

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE7EAF0),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor:
                                      const Color(0xFFE8F0FF),
                                  child: const Icon(
                                    Icons.person,
                                    color: Color(0xFF344D9A),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        phone,
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: deleteContact,
                                  tooltip: 'Delete contact',
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Compact green call button
                            SizedBox(
                              height: 36,
                              child: ElevatedButton.icon(
                                onPressed: phone.isEmpty
                                    ? null
                                    : () => callContact(phone),
                                icon: const Icon(
                                  Icons.call,
                                  size: 17,
                                ),
                                label: const Text(
                                  'CALL',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: greenColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 22,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(9),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const Spacer(),

                  // Main Emergency SOS section
                  Icon(
                    Icons.warning_rounded,
                    size: constraints.maxHeight < 650 ? 48 : 60,
                    color: redColor,
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'EMERGENCY SOS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: redColor,
                      fontSize: constraints.maxHeight < 650 ? 27 : 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Tap below to alert your caretaker',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 18),

                  SizedBox(
                    width: constraints.maxWidth < 380 ? 170 : 190,
                    height: constraints.maxHeight < 650 ? 110 : 130,
                    child: ElevatedButton(
                      onPressed: isSendingSOS ? null : sendSOS,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: redColor,
                        foregroundColor: Colors.white,
                        elevation: 5,
                        shape: const CircleBorder(),
                      ),
                      child: isSendingSOS
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(height: 3),
                                Text(
                                  'SOS',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const Spacer(),

                  const Padding(
                    padding: EdgeInsets.only(bottom: 12, top: 8),
                    child: Text(
                      'Use SOS only in an emergency',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black45,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
