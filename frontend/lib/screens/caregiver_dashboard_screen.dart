
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'elder_monitoring_screen.dart';
import 'doctor_appointment_screen.dart';
import 'medicine_reminder_screen.dart';
import 'medicine_stock_screen.dart';
import 'caregiver_elder_link_screen.dart';

class CaregiverDashboardScreen extends StatefulWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  State<CaregiverDashboardScreen> createState() =>
      _CaregiverDashboardScreenState();
}

class _CaregiverDashboardScreenState
    extends State<CaregiverDashboardScreen> {
  User? get currentUser => FirebaseAuth.instance.currentUser;

  void openScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'taken':
        return Colors.green;
      case 'missed':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String formatSosTime(dynamic value) {
    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    }

    if (date == null) return 'Time not available';

    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year} at $hour:$minute $period';
  }

  // ================= MEDICINE STATUS =================

  Widget buildMedicineStatus() {
    final user = currentUser;

    if (user == null) {
      return const Card(
        child: ListTile(
          title: Text('Please login again.'),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, caregiverSnapshot) {
        if (caregiverSnapshot.hasError) {
          return const Card(
            child: ListTile(
              leading: Icon(Icons.error_outline, color: Colors.red),
              title: Text('Unable to load linked elder.'),
            ),
          );
        }

        if (!caregiverSnapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final caregiverData = caregiverSnapshot.data!.data();
        final elderId = caregiverData?['elderId']?.toString();

        if (elderId == null || elderId.isEmpty) {
          return const Card(
            child: ListTile(
              leading: Icon(
                Icons.person_search,
                color: Colors.teal,
                size: 32,
              ),
              title: Text(
                'No Elder Linked',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Use Connect Elder to link an elder account.',
              ),
            ),
          );
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(elderId)
              .collection('medicine_reminders')
              .snapshots(),
          builder: (context, reminderSnapshot) {
            if (reminderSnapshot.hasError) {
              return const Card(
                child: ListTile(
                  leading: Icon(Icons.error_outline, color: Colors.red),
                  title: Text('Unable to load medicine status.'),
                ),
              );
            }

            if (!reminderSnapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final docs = reminderSnapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return const Card(
                child: ListTile(
                  leading: Icon(
                    Icons.medication_outlined,
                    color: Colors.blue,
                    size: 32,
                  ),
                  title: Text(
                    'No Medicine Reminders',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Medicine status will appear here after a reminder is added.',
                  ),
                ),
              );
            }

            final sortedDocs = [...docs];

            sortedDocs.sort((a, b) {
              final aTime = a.data()['time']?.toString() ?? '';
              final bTime = b.data()['time']?.toString() ?? '';
              return aTime.compareTo(bTime);
            });

            return Column(
              children: sortedDocs.map((doc) {
                final data = doc.data();
                final medicine =
                    data['medicine']?.toString() ?? 'Medicine';
                final time =
                    data['time']?.toString() ?? 'Time not set';
                final foodTiming =
                    data['foodTiming']?.toString() ?? '';
                final status =
                    data['status']?.toString() ?? 'Pending';
                final color = statusColor(status);

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.12),
                      child: Icon(
                        status.toLowerCase() == 'taken'
                            ? Icons.check_circle
                            : status.toLowerCase() == 'missed'
                                ? Icons.cancel
                                : Icons.schedule,
                        color: color,
                      ),
                    ),
                    title: Text(
                      medicine,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '$time'
                      '${foodTiming.isNotEmpty ? '\n$foodTiming' : ''}',
                    ),
                    isThreeLine: foodTiming.isNotEmpty,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  // ================= SOS ALERTS =================

  Widget buildSosAlerts() {
    final user = currentUser;

    if (user == null) {
      return const Text('Please login again.');
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, caregiverSnapshot) {
        if (caregiverSnapshot.hasError) {
          return const Text('Unable to load SOS alerts.');
        }

        if (!caregiverSnapshot.hasData) {
          return const LinearProgressIndicator();
        }

        final caregiverData = caregiverSnapshot.data!.data();
        final elderId = caregiverData?['elderId']?.toString();

        if (elderId == null || elderId.isEmpty) {
          return const Card(
            child: ListTile(
              dense: true,
              title: Text('Connect an elder to receive SOS alerts.'),
            ),
          );
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(elderId)
              .collection('sos_alerts')
              .snapshots(),
          builder: (context, sosSnapshot) {
            if (sosSnapshot.hasError) {
              return const Card(
                child: ListTile(
                  leading: Icon(Icons.error_outline, color: Colors.red),
                  title: Text('Unable to load SOS alerts.'),
                ),
              );
            }

            if (!sosSnapshot.hasData) {
              return const LinearProgressIndicator();
            }

            // Show alerts not yet resolved.
            final docs = sosSnapshot.data!.docs
                .where((doc) =>
                    (doc.data()['status']?.toString() ?? 'active')
                        .toLowerCase() !=
                    'resolved')
                .toList();

            docs.sort((a, b) {
              final aDate = a.data()['createdAt'];
              final bDate = b.data()['createdAt'];

              final aMillis = aDate is Timestamp
                  ? aDate.millisecondsSinceEpoch
                  : 0;
              final bMillis = bDate is Timestamp
                  ? bDate.millisecondsSinceEpoch
                  : 0;

              return bMillis.compareTo(aMillis);
            });

            if (docs.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.notifications_none,
                      color: Colors.grey,
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'No SOS alerts',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: docs.map((doc) {
                final data = doc.data();
                final elderName =
                    data['elderName']?.toString() ?? 'Elder';
                final time = formatSosTime(data['createdAt']);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  color: Colors.red.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: Colors.red.shade200,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.emergency,
                            color: Colors.red.shade700,
                            size: 27,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$elderName pressed SOS',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: Colors.red.shade700,
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      time,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => markSosResolved(doc),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 11,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                          child: const Text(
                            'Mark\nResolved',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
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
      },
    );
  }

  Future<void> markSosResolved(
    QueryDocumentSnapshot<Map<String, dynamic>> alert,
  ) async {
    try {
      await alert.reference.update({
        'status': 'resolved',
        'resolvedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SOS alert marked as resolved.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to resolve SOS alert.'),
        ),
      );
    }
  }

  // ================= FEATURE CARD =================

  Widget buildFeatureCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 105,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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

  // ================= DASHBOARD =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Caretaker Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome Caretaker',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Manage your elder\'s health and stay connected with ease.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Quick Access',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: buildFeatureCard(
                    title: 'Elder Monitoring',
                    icon: Icons.monitor_heart,
                    color: Colors.deepPurple,
                    onTap: () {
                      openScreen(const ElderMonitoringScreen());
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: buildFeatureCard(
                    title: 'Connect Elder',
                    icon: Icons.family_restroom,
                    color: Colors.teal,
                    onTap: () {
                      openScreen(const CaregiverElderLinkScreen());
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: buildFeatureCard(
                    title: 'Medicine Reminder',
                    icon: Icons.alarm,
                    color: Colors.blue,
                    onTap: () {
                      openScreen(const MedicineReminderScreen());
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: buildFeatureCard(
                    title: 'Medicine Stock',
                    icon: Icons.inventory_2,
                    color: Colors.orange,
                    onTap: () {
                      openScreen(const MedicineStockScreen());
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: buildFeatureCard(
                    title: 'Doctor Appointment',
                    icon: Icons.local_hospital,
                    color: Colors.green,
                    onTap: () {
                      openScreen(const DoctorAppointmentScreen());
                    },
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(child: SizedBox(height: 105)),
              ],
            ),

            sectionTitle(
              'SOS Alerts',
              Icons.notifications_active,
            ),
            buildSosAlerts(),

            sectionTitle(
              'Medicine Status',
              Icons.medication,
            ),
            buildMedicineStatus(),

            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }
}
