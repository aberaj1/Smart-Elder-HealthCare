import 'package:flutter/material.dart';

import 'doctor_appointment_screen.dart';
import 'emergency_screen.dart';
import 'login_screen.dart';
import 'medicine_reminder_screen.dart';
import 'medicine_stock_screen.dart';
import 'profile_screen.dart';

class ElderDashboardScreen extends StatelessWidget {
  const ElderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Elder Dashboard'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hello Elder 👋',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Manage your medicines and healthcare activities easily.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Quick Access',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const MedicineScreen(),
                        ),
                      );
                    },
                    child: dashboardCard(
                      Icons.alarm,
                      'Medicine',
                      'Reminder',
                      Colors.blue,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const MedicineStockScreen(),
                        ),
                      );
                    },
                    child: dashboardCard(
                      Icons.inventory_2,
                      'Medicine',
                      'Stock',
                      Colors.orange,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const DoctorAppointmentScreen(),
                        ),
                      );
                    },
                    child: dashboardCard(
                      Icons.calendar_month,
                      'Doctor',
                      'Appointment',
                      Colors.green,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const EmergencyScreen(),
                        ),
                      );
                    },
                    child: dashboardCard(
                      Icons.emergency,
                      'Emergency',
                      'SOS',
                      Colors.red,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            const Text(
              "Today's Reminder",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            ValueListenableBuilder<
                List<Map<String, String>>>(
              valueListenable: reminderNotifier,
              builder: (
                context,
                reminders,
                child,
              ) {
                if (reminders.isEmpty) {
                  return const Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.alarm,
                        color: Colors.blue,
                        size: 35,
                      ),
                      title: Text(
                        'No reminders yet',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Add your medicine schedule',
                      ),
                    ),
                  );
                }

                return Column(
                  children: reminders.map(
                    (reminder) {
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(
                          bottom: 10,
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.medication,
                            color: Colors.blue,
                            size: 35,
                          ),
                          title: Text(
                            reminder['medicine']!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'Time: ${reminder['time']}',
                          ),
                          trailing: const Icon(
                            Icons.alarm,
                            color: Colors.orange,
                          ),
                        ),
                      );
                    },
                  ).toList(),
                );
              },
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ProfileScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.person),
                label: const Text(
                  'My Profile',
                  style: TextStyle(fontSize: 17),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget dashboardCard(
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              size: 45,
              color: color,
            ),

            const SizedBox(height: 10),

            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}