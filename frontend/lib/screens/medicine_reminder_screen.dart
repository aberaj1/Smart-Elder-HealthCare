import 'package:flutter/material.dart';

class MedicineScreen extends StatefulWidget {
  const MedicineScreen({super.key});

  @override
  State<MedicineScreen> createState() => _MedicineScreenState();
}

class _MedicineScreenState extends State<MedicineScreen> {
  final TextEditingController medicineController =
      TextEditingController();

  final TextEditingController timeController =
      TextEditingController();

  String medicineName = '';
  String medicineTime = '';

  @override
  void dispose() {
    medicineController.dispose();
    timeController.dispose();
    super.dispose();
  }

  void addReminder() {
    final medicine = medicineController.text.trim();
    final time = timeController.text.trim();

    if (medicine.isEmpty || time.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both medicine name and time.'),
        ),
      );
      return;
    }

    setState(() {
      medicineName = medicine;
      medicineTime = time;
    });

    medicineController.clear();
    timeController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Medicine reminder added!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Reminder'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Medicine',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: medicineController,
              decoration: const InputDecoration(
                labelText: 'Medicine Name',
                hintText: 'Example: Paracetamol',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medication),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: timeController,
              decoration: const InputDecoration(
                labelText: 'Time',
                hintText: 'Example: 08:00 AM',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.access_time),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: addReminder,
                icon: const Icon(Icons.add),
                label: const Text('Add Reminder'),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'My Reminder',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            if (medicineName.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(
                    Icons.alarm,
                    color: Colors.blue,
                  ),
                  title: Text('No reminder added'),
                  subtitle: Text(
                    'Add medicine name and time above',
                  ),
                ),
              )
            else
              Card(
                elevation: 3,
                child: ListTile(
                  leading: const Icon(
                    Icons.medication,
                    color: Colors.blue,
                    size: 40,
                  ),
                  title: Text(
                    medicineName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    'Time: $medicineTime',
                  ),
                  trailing: const Icon(
                    Icons.alarm,
                    color: Colors.orange,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}