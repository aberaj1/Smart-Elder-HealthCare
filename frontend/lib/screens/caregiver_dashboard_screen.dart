import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'medicine_reminder_screen.dart';
import 'medicine_stock_screen.dart';
import 'doctor_appointment_screen.dart';
import 'emergency_screen.dart';

class CaregiverDashboardScreen extends StatelessWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caregiver Dashboard'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
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
              'Hello Caregiver 👋',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'Monitor your elder healthcare activities',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Elder Information',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Card(
              elevation: 3,
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                  ),
                ),
                title: const Text(
                  'Elder User',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'Healthcare monitoring',
                ),
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
                    child: caregiverCard(
                      Icons.medication,
                      'Medicine',
                      'Status',
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
                    child: caregiverCard(
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
                    child: caregiverCard(
                      Icons.calendar_month,
                      'Doctor',
                      'Appointments',
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
                    child: caregiverCard(
                      Icons.emergency,
                      'Emergency',
                      'Alerts',
                      Colors.red,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            Card(
              elevation: 3,
              child: ListTile(
                leading: const Icon(
                  Icons.notifications_active,
                  color: Colors.orange,
                  size: 35,
                ),
                title: const Text(
                  'No alerts',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'Elder healthcare alerts will appear here',
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text(
                  'Logout',
                  style: TextStyle(fontSize: 17),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget caregiverCard(
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
            ),
          ],
        ),
      ),
    );
  }
}