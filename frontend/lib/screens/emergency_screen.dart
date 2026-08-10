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

  String contactName = '';
  String contactPhone = '';

  bool emergencyActivated = false;

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void saveContact() {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter contact name and phone number.',
          ),
        ),
      );
      return;
    }

    setState(() {
      contactName = name;
      contactPhone = phone;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Emergency contact saved successfully!',
        ),
      ),
    );
  }

  void activateEmergency() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Emergency SOS'),
          content: Text(
            contactName.isEmpty
                ? 'No emergency contact is saved. Do you want to activate SOS?'
                : 'Emergency assistance will be activated for $contactName.',
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

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Emergency assistance activated!',
                    ),
                  ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency SOS'),
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
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: 'Example: 9876543210',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: saveContact,
                icon: const Icon(Icons.save),
                label: const Text('Save Emergency Contact'),
              ),
            ),

            const SizedBox(height: 25),

            if (contactName.isNotEmpty)
              Card(
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
                  subtitle: Text(contactPhone),
                  trailing: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
              ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 65,
              child: ElevatedButton.icon(
                onPressed: activateEmergency,
                icon: const Icon(
                  Icons.warning,
                  size: 30,
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
                    borderRadius: BorderRadius.circular(12),
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

                      Expanded(
                        child: Text(
                          contactName.isEmpty
                              ? 'Emergency assistance activated.'
                              : 'Emergency assistance activated for $contactName ($contactPhone).',
                          style: const TextStyle(
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