import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'medicine_scan_screen.dart';
import 'doctor_appointment_screen.dart';
import 'emergency_screen.dart';
import 'medicine_reminder_screen.dart';
import 'medicine_stock_screen.dart';
import 'caregiver_elder_link_screen.dart';

class ElderDashboardScreen extends StatefulWidget {
  const ElderDashboardScreen({super.key});

  @override
  State<ElderDashboardScreen> createState() =>
      _ElderDashboardScreenState();
}

class _ElderDashboardScreenState
    extends State<ElderDashboardScreen> {
  User? get currentUser => FirebaseAuth.instance.currentUser;

  void openScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => screen,
      ),
    );
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Elder Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green,
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
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            // Welcome
            const Text(
              'Welcome Elder',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            const Text(
              'Smart Elder Healthcare',
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

            // Row 1
            Row(
              children: [

                Expanded(
                  child: buildFeatureCard(
                    title: 'Medicine Reminder',
                    icon: Icons.alarm,
                    color: Colors.blue,
                    onTap: () {
                      openScreen(
                        const MedicineReminderScreen(),
                      );
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
                      openScreen(
                        const MedicineStockScreen(),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Row 2
            Row(
              children: [

                Expanded(
                  child: buildFeatureCard(
                    title: 'Doctor Appointment',
                    icon: Icons.local_hospital,
                    color: Colors.green,
                    onTap: () {
                      openScreen(
                        const DoctorAppointmentScreen(),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: buildFeatureCard(
                    title: 'Emergency SOS',
                    icon: Icons.emergency,
                    color: Colors.red,
                    onTap: () {
                      openScreen(
                        const EmergencyScreen(),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Row 3
            Row(
              children: [

                Expanded(
                  child: buildFeatureCard(
                    title: 'Medicine Scan',
                    icon: Icons.camera_alt,
                    color: Colors.purple,
                    onTap: () {
                      openScreen(
                        const MedicineScanScreen(),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: buildFeatureCard(
                    title: 'Caregiver Link',
                    icon: Icons.family_restroom,
                    color: Colors.teal,
                    onTap: () {
                      openScreen(
                        const CaregiverElderLinkScreen(),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Today's Reminder
            const Text(
              'Today\'s Reminder',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Card(
              elevation: 2,
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Icon(
                    Icons.notifications_active,
                    color: Colors.white,
                  ),
                ),
                title: const Text(
                  'Medicine Reminders',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'Open Medicine Reminder to view your schedules.',
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                ),
                onTap: () {
                  openScreen(
                    const MedicineReminderScreen(),
                  );
                },
              ),
            ),

            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

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
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [

                Icon(
                  icon,
                  color: color,
                  size: 32,
                ),

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
}