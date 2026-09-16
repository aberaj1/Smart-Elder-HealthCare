import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
          'Caregiver Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
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
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            // Welcome
            const Text(
              'Welcome Caregiver',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            const Text(
              'Caregiver Healthcare Management',
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
                    title: 'Elder Monitoring',
                    icon: Icons.monitor_heart,
                    color: Colors.deepPurple,
                    onTap: () {
                      openScreen(
                        const ElderMonitoringScreen(),
                      );
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
                      openScreen(
                        const CaregiverElderLinkScreen(),
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

            // Row 3
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

                const Expanded(
                  child: SizedBox(
                    height: 105,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Information
            Card(
              elevation: 2,
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.white,
                  ),
                ),
                title: const Text(
                  'Caregiver Monitoring',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'Connect an elder to view their healthcare details.',
                ),
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