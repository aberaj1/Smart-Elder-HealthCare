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

  @override
  void initState() {
    super.initState();
    loadLinkedElder();
  }

  // ================= LOAD LINKED ELDER =================

  Future<void> loadLinkedElder() async {
    if (currentUser == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final caregiverDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (!caregiverDoc.exists) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final caregiverData = caregiverDoc.data();

      if (caregiverData == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final id = caregiverData['elderId'];

      if (id == null || id.toString().isEmpty) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      elderId = id.toString();

      final elderDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(elderId)
          .get();

      if (elderDoc.exists) {
        final data = elderDoc.data();

        if (data != null) {
          setState(() {
            elderName = data['name']?.toString() ?? 'Elder';
            elderEmail = data['email']?.toString() ?? '';
            isLoading = false;
          });

          return;
        }
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      showMessage('Unable to load elder details.');
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

  // ================= EMPTY CARD =================

  Widget emptyCard(
    String message,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.grey,
              size: 30,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= ELDER PROFILE =================

  Widget buildElderProfile() {
    return Card(
      elevation: 3,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 32,
              child: Icon(
                Icons.person,
                size: 35,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Linked Elder',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    elderName ?? 'Elder',
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (elderEmail != null &&
                      elderEmail!.isNotEmpty)
                    Text(
                      elderEmail!,
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= MEDICINE REMINDERS =================

  Widget buildMedicineReminders() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(elderId)
          .collection('medicine_reminders')
          .orderBy('time')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return emptyCard(
            'Unable to load medicine reminders.',
            Icons.error_outline,
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return emptyCard(
            'No medicine reminders found.',
            Icons.medication_outlined,
          );
        }

        return Column(
          children: docs.map((doc) {
            final data =
                doc.data() as Map<String, dynamic>;

            final medicine =
                data['medicine']?.toString() ?? 'Medicine';

            final strength =
                data['strength']?.toString() ?? '';

            final time =
                data['time']?.toString() ?? '';

            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(
                    Icons.medication,
                  ),
                ),
                title: Text(
                  medicine,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  strength.isEmpty
                      ? 'Medicine reminder'
                      : strength,
                ),
                trailing: Text(
                  time,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ================= MEDICINE STOCK =================

  Widget buildMedicineStock() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(elderId)
          .collection('medicine_stock')
          .orderBy('medicineName')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return emptyCard(
            'Unable to load medicine stock.',
            Icons.error_outline,
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return emptyCard(
            'No medicine stock found.',
            Icons.inventory_2_outlined,
          );
        }

        return Column(
          children: docs.map((doc) {
            final data =
                doc.data() as Map<String, dynamic>;

            final medicine =
                data['medicineName']?.toString() ??
                    'Medicine';

            final quantity =
                data['quantity'] ?? 0;

            final expiryDate =
                data['expiryDate']?.toString() ?? '';

            final int qty =
                int.tryParse(quantity.toString()) ?? 0;

            final bool lowStock = qty <= 5;

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      lowStock
                          ? Colors.orange.shade100
                          : Colors.green.shade100,
                  child: Icon(
                    Icons.inventory_2,
                    color:
                        lowStock
                            ? Colors.orange
                            : Colors.green,
                  ),
                ),
                title: Text(
                  medicine,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  expiryDate.isEmpty
                      ? 'Expiry date not available'
                      : 'Expiry: $expiryDate',
                ),
                trailing: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  crossAxisAlignment:
                      CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$qty',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color:
                            lowStock
                                ? Colors.orange
                                : Colors.green,
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

  // ================= APPOINTMENTS =================

  Widget buildAppointments() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(elderId)
          .collection('appointments')
          .orderBy('date')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return emptyCard(
            'Unable to load appointments.',
            Icons.error_outline,
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return emptyCard(
            'No doctor appointments found.',
            Icons.calendar_month,
          );
        }

        return Column(
          children: docs.map((doc) {
            final data =
                doc.data() as Map<String, dynamic>;

            final doctor =
                data['doctor']?.toString() ??
                    'Doctor';

            final specialization =
                data['specialization']?.toString() ??
                    '';

            final date =
                data['date'];

            final time =
                data['time']?.toString() ?? '';

            String dateText = '';

            if (date is Timestamp) {
              final d = date.toDate();

              dateText =
                  '${d.day.toString().padLeft(2, '0')}/'
                  '${d.month.toString().padLeft(2, '0')}/'
                  '${d.year}';
            }

            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(
                    Icons.local_hospital,
                  ),
                ),
                title: Text(
                  doctor,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '$specialization\n$dateText',
                ),
                isThreeLine: true,
                trailing: Text(
                  time,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ================= EMERGENCY CONTACT =================

  Widget buildEmergencyContact() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(elderId)
          .collection('emergency_contacts')
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return emptyCard(
            'Unable to load emergency contact.',
            Icons.error_outline,
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return emptyCard(
            'No emergency contact saved.',
            Icons.contact_phone,
          );
        }

        final data =
            docs.first.data()
                as Map<String, dynamic>;

        final name =
            data['name']?.toString() ??
                'Emergency Contact';

        final phone =
            data['phone']?.toString() ?? '';

        return Card(
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.red,
              child: Icon(
                Icons.emergency,
                color: Colors.white,
              ),
            ),
            title: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(phone),
          ),
        );
      },
    );
  }

  // ================= SECTION TITLE =================

  Widget sectionTitle(
    String title,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 20,
        bottom: 10,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.blue,
          ),
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

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Elder Monitoring'),
        ),
        body: const Center(
          child: Text('Please login first.'),
        ),
      );
    }

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Elder Monitoring'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (elderId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Elder Monitoring',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
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
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 25),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
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
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            buildElderProfile(),

            sectionTitle(
              'Medicine Reminders',
              Icons.medication,
            ),
            buildMedicineReminders(),

            sectionTitle(
              'Medicine Stock',
              Icons.inventory_2,
            ),
            buildMedicineStock(),

            sectionTitle(
              'Doctor Appointments',
              Icons.calendar_month,
            ),
            buildAppointments(),

            sectionTitle(
              'Emergency Contact',
              Icons.emergency,
            ),
            buildEmergencyContact(),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}