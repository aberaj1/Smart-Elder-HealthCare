import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController phoneController =
      TextEditingController();

  bool emergencyActivated = false;
  bool isSaving = false;

  User? get currentUser => FirebaseAuth.instance.currentUser;

  CollectionReference<Map<String, dynamic>> get emergencyCollection {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('emergency_contacts');
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> saveContact() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      showMessage(
        'Please enter contact name and phone number.',
      );
      return;
    }

    if (phone.length < 10) {
      showMessage(
        'Please enter a valid phone number.',
      );
      return;
    }

    if (currentUser == null) {
      showMessage('Please login first.');
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      // Remove old emergency contacts
      final oldContacts = await emergencyCollection.get();

      for (final doc in oldContacts.docs) {
        await doc.reference.delete();
      }

      // Save new contact
      await emergencyCollection.add({
        'name': name,
        'phone': phone,
        'userId': currentUser!.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        isSaving = false;
      });

      showMessage(
        'Emergency contact saved successfully!',
      );
    } catch (e) {
      setState(() {
        isSaving = false;
      });

      showMessage(
        'Error saving contact: $e',
      );
    }
  }

  Future<void> deleteContact(String documentId) async {
    try {
      await emergencyCollection
          .doc(documentId)
          .delete();

      showMessage('Emergency contact deleted.');
    } catch (e) {
      showMessage('Unable to delete contact.');
    }
  }

  void activateEmergency(
    String contactName,
    String contactPhone,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.warning,
                color: Colors.red,
              ),
              SizedBox(width: 8),
              Text('Emergency SOS'),
            ],
          ),
          content: Text(
            contactName.isEmpty
                ? 'No emergency contact is saved. Do you want to activate SOS?'
                : 'Emergency assistance will be activated for '
                    '$contactName ($contactPhone).',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);

                setState(() {
                  emergencyActivated = true;
                });

                showMessage(
                  'Emergency assistance activated!',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('CONFIRM SOS'),
            ),
          ],
        );
      },
    );
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Emergency SOS'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Please login first'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Emergency SOS',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.emergency,
              size: 80,
              color: Colors.red,
            ),

            const SizedBox(height: 15),

            const Text(
              'Emergency Assistance',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 10),

            const Text(
              'Add a family member or caregiver as your emergency contact.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 25),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Contact Name',
                hintText: 'Example: Dad',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: 'Example: 9876543210',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
                counterText: '',
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : saveContact,
                icon: isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  isSaving
                      ? 'Saving...'
                      : 'Save Emergency Contact',
                ),
              ),
            ),

            const SizedBox(height: 25),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Saved Emergency Contact',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 12),

            StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: emergencyCollection
                  .orderBy(
                    'createdAt',
                    descending: true,
                  )
                  .snapshots(),

              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Error loading contact:\n'
                        '${snapshot.error}',
                      ),
                    ),
                  );
                }

                final documents =
                    snapshot.data?.docs ?? [];

                if (documents.isEmpty) {
                  return const Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.contact_phone,
                        color: Colors.grey,
                        size: 35,
                      ),
                      title: Text(
                        'No emergency contact saved',
                      ),
                      subtitle: Text(
                        'Add a family member or caregiver',
                      ),
                    ),
                  );
                }

                final doc = documents.first;
                final data = doc.data();

                final String contactName =
                    data['name'] ?? '';

                final String contactPhone =
                    data['phone'] ?? '';

                return Card(
                  elevation: 3,
                  child: ListTile(
                    leading: const Icon(
                      Icons.contact_phone,
                      color: Colors.green,
                      size: 40,
                    ),

                    title: Text(
                      contactName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    subtitle: Text(
                      contactPhone,
                    ),

                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        deleteContact(doc.id);
                      },
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 70,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final snapshot =
                      await emergencyCollection.limit(1).get();

                  String name = '';
                  String phone = '';

                  if (snapshot.docs.isNotEmpty) {
                    final data =
                        snapshot.docs.first.data();

                    name = data['name'] ?? '';
                    phone = data['phone'] ?? '';
                  }

                  activateEmergency(name, phone);
                },

                icon: const Icon(
                  Icons.warning,
                  size: 32,
                ),

                label: const Text(
                  'EMERGENCY SOS',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            if (emergencyActivated)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.red,
                        size: 30,
                      ),

                      const SizedBox(width: 12),

                      const Expanded(
                        child: Text(
                          'Emergency assistance activated.',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
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