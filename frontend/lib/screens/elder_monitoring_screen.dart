
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ElderMonitoringScreen extends StatefulWidget {
  const ElderMonitoringScreen({super.key});

  @override
  State<ElderMonitoringScreen> createState() =>
      _ElderMonitoringScreenState();
}

class _ElderMonitoringScreenState
    extends State<ElderMonitoringScreen> {
  User? get currentUser => FirebaseAuth.instance.currentUser;

  String? elderId;
  String? elderName;
  String? elderEmail;
  bool isLoading = true;

  CollectionReference<Map<String, dynamic>> get emergencyContacts =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(elderId)
          .collection('emergency_contacts');

  @override
  void initState() {
    super.initState();
    loadLinkedElder();
  }

  Future<void> loadLinkedElder() async {
    final user = currentUser;

    if (user == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    try {
      final caregiverDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final caregiverData = caregiverDoc.data();
      final linkedId = caregiverData?['elderId']?.toString();

      if (linkedId == null || linkedId.isEmpty) {
        if (mounted) setState(() => isLoading = false);
        return;
      }

      final elderDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(linkedId)
          .get();

      final data = elderDoc.data();

      if (!mounted) return;

      setState(() {
        elderId = linkedId;
        elderName = data?['name']?.toString() ?? 'Elder';
        elderEmail = data?['email']?.toString() ?? '';
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      showMessage('Unable to load linked elder details.');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget emptyCard(String message, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildElderProfile() {
    return Card(
      elevation: 2,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              child: Icon(Icons.person, size: 32),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Linked Elder',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    elderName ?? 'Elder',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (elderEmail?.isNotEmpty == true)
                    Text(
                      elderEmail!,
                      style: const TextStyle(color: Colors.grey),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color reminderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'taken':
        return Colors.green;
      case 'missed':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Widget buildMedicineReminders() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(elderId)
          .collection('medicine_reminders')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return emptyCard(
            'Unable to load medicine reminders.',
            Icons.error_outline,
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs.toList();

        docs.sort((a, b) =>
            (a.data()['time'] ?? '').toString().compareTo(
                  (b.data()['time'] ?? '').toString(),
                ));

        if (docs.isEmpty) {
          return emptyCard(
            'No medicine reminders found.',
            Icons.medication_outlined,
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data();
            final medicine = data['medicine']?.toString() ?? 'Medicine';
            final strength = data['strength']?.toString() ?? '';
            final time = data['time']?.toString() ?? '';
            final status = data['status']?.toString() ?? 'Pending';
            final color = reminderStatusColor(status);

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.medication),
                ),
                title: Text(
                  medicine,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  [
                    if (strength.isNotEmpty) strength,
                    'Status: $status',
                  ].join('\n'),
                ),
                isThreeLine: true,
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.access_time, color: Colors.blue),
                    const SizedBox(height: 4),
                    Text(time.isEmpty ? '--:--' : time),
                  ],
                ),
                titleTextStyle: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                ),
                iconColor: color,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  String formatExpiryDate(dynamic value) {
    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    } else if (value is String) {
      date = DateTime.tryParse(value);
    }

    if (date == null) return 'Expiry date not available';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Widget buildMedicineStock() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(elderId)
          .collection('medicine_stock')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return emptyCard(
            'Unable to load medicine stock.',
            Icons.error_outline,
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return emptyCard(
            'No medicine stock found.',
            Icons.inventory_2_outlined,
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data();
            final medicine = data['medicineName']?.toString() ?? 'Medicine';
            final quantity =
                int.tryParse('${data['quantity'] ?? 0}') ?? 0;
            final lowStock = quantity <= 5;

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      lowStock ? Colors.orange.shade100 : Colors.green.shade100,
                  child: Icon(
                    Icons.inventory_2,
                    color: lowStock ? Colors.orange : Colors.green,
                  ),
                ),
                title: Text(
                  medicine,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Expiry: ${formatExpiryDate(data['expiryDate'])}',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$quantity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: lowStock ? Colors.orange : Colors.green,
                      ),
                    ),
                    if (lowStock)
                      const Text(
                        'Low Stock',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget buildAppointments() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(elderId)
          .collection('appointments')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return emptyCard(
            'Unable to load appointments.',
            Icons.error_outline,
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs.toList();

        docs.sort((a, b) {
          final aDate = a.data()['date'];
          final bDate = b.data()['date'];

          final aTime = aDate is Timestamp
              ? aDate.toDate()
              : DateTime.tryParse('$aDate') ?? DateTime(2100);
          final bTime = bDate is Timestamp
              ? bDate.toDate()
              : DateTime.tryParse('$bDate') ?? DateTime(2100);

          return aTime.compareTo(bTime);
        });

        if (docs.isEmpty) {
          return emptyCard(
            'No doctor appointments found.',
            Icons.calendar_month,
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data();
            final doctor = data['doctor']?.toString() ?? 'Doctor';
            final specialization =
                data['specialization']?.toString() ?? '';
            final time = data['time']?.toString() ?? '';
            final date = data['date'];

            String dateText = '';

            if (date is Timestamp) {
              final d = date.toDate();
              dateText =
                  '${d.day.toString().padLeft(2, '0')}/'
                  '${d.month.toString().padLeft(2, '0')}/'
                  '${d.year}';
            } else if (date is String) {
              dateText = date;
            }

            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.local_hospital),
                ),
                title: Text(
                  doctor,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('$specialization\n$dateText'),
                isThreeLine: true,
                trailing: Text(
                  time,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // FIXED: Listen to the same emergency_contacts collection used by
  // EmergencyScreen. Prefer the "primary" document and fall back to
  // existing contacts created with auto-generated document IDs.
  Widget buildEmergencyContact() {
    if (elderId == null || elderId!.isEmpty) {
      return emptyCard(
        'No linked elder found.',
        Icons.contact_phone,
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: emergencyContacts.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return emptyCard(
            'Unable to load emergency contact. Check Firestore rules.',
            Icons.error_outline,
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return emptyCard(
            'No emergency contact saved.',
            Icons.contact_phone,
          );
        }

        // Use the fixed "primary" contact when available.
        // Otherwise display an older contact saved with an auto-ID.
        final primaryDocs =
            docs.where((doc) => doc.id == 'primary').toList();

        final selectedDoc =
            primaryDocs.isNotEmpty ? primaryDocs.first : docs.first;

        final data = selectedDoc.data();
        final name = data['name']?.toString() ?? 'Emergency Contact';
        final phone = data['phone']?.toString() ?? '';

        return Card(
          elevation: 2,
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.red,
              child: Icon(Icons.emergency, color: Colors.white),
            ),
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              phone.isEmpty ? 'Phone number not available' : phone,
            ),
            trailing: const Icon(
              Icons.check_circle,
              color: Colors.green,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Elder Monitoring')),
        body: const Center(child: Text('Please login first.')),
      );
    }

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Elder Monitoring')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (elderId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Elder Monitoring'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.person_search,
                  size: 80,
                  color: Colors.grey,
                ),
                const SizedBox(height: 20),
                const Text(
                  'No Elder Linked',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Please link an elder using the Elder Link Code.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 25),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Elder Monitoring',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildElderProfile(),

            sectionTitle('Medicine Reminders', Icons.medication),
            buildMedicineReminders(),

            sectionTitle('Medicine Stock', Icons.inventory_2),
            buildMedicineStock(),

            sectionTitle('Doctor Appointments', Icons.calendar_month),
            buildAppointments(),

            sectionTitle('Emergency Contact', Icons.emergency),
            buildEmergencyContact(),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
