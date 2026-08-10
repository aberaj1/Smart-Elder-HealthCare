import 'package:flutter/material.dart';

// Shared reminder data
final ValueNotifier<List<Map<String, String>>> reminderNotifier =
    ValueNotifier<List<Map<String, String>>>([]);

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

  final List<String> medicineSuggestions = [
    'Paracetamol Tablet',
    'Pantoprazole Tablet',
    'Amoxicillin Tablet',
    'Aspirin Tablet',
    'Cetirizine Tablet',
    'Ibuprofen Tablet',
    'Metformin Tablet',
  ];

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
          content: Text(
            'Please enter medicine name and time.',
          ),
        ),
      );
      return;
    }

    reminderNotifier.value = [
      ...reminderNotifier.value,
      {
        'medicine': medicine,
        'time': time,
      },
    ];

    medicineController.clear();
    timeController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Medicine reminder added successfully!',
        ),
      ),
    );
  }

  void deleteReminder(int index) {
    final updatedList = [...reminderNotifier.value];
    updatedList.removeAt(index);

    reminderNotifier.value = updatedList;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reminder deleted.'),
      ),
    );
  }

  Future<void> selectTime() async {
    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (selectedTime != null) {
      setState(() {
        timeController.text = selectedTime.format(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Reminder'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
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

            Autocomplete<String>(
              optionsBuilder: (
                TextEditingValue value,
              ) {
                if (value.text.isEmpty) {
                  return const Iterable<String>.empty();
                }

                return medicineSuggestions.where(
                  (medicine) => medicine
                      .toLowerCase()
                      .contains(
                        value.text.toLowerCase(),
                      ),
                );
              },

              onSelected: (String value) {
                medicineController.text = value;
              },

              fieldViewBuilder: (
                context,
                controller,
                focusNode,
                onFieldSubmitted,
              ) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,

                  onChanged: (value) {
                    medicineController.text = value;
                  },

                  decoration: const InputDecoration(
                    labelText: 'Medicine Name',
                    hintText: 'Type medicine name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(
                      Icons.medication,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 15),

            TextField(
              controller: timeController,
              readOnly: true,
              onTap: selectTime,
              decoration: const InputDecoration(
                labelText: 'Medicine Time',
                hintText: 'Select time',
                border: OutlineInputBorder(),
                prefixIcon: Icon(
                  Icons.access_time,
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: addReminder,
                icon: const Icon(Icons.add),
                label: const Text(
                  'Add Reminder',
                ),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'My Reminders',
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
                      ),
                      title: Text(
                        'No reminders added',
                      ),
                      subtitle: Text(
                        'Add medicine name and time above',
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics:
                      const NeverScrollableScrollPhysics(),
                  itemCount: reminders.length,

                  itemBuilder: (
                    context,
                    index,
                  ) {
                    final reminder =
                        reminders[index];

                    return Card(
                      elevation: 3,
                      margin:
                          const EdgeInsets.only(
                        bottom: 12,
                      ),

                      child: ListTile(
                        leading: const Icon(
                          Icons.medication,
                          color: Colors.blue,
                          size: 40,
                        ),

                        title: Text(
                          reminder['medicine']!,
                          style: const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),

                        subtitle: Text(
                          'Time: ${reminder['time']}',
                        ),

                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),

                          onPressed: () {
                            deleteReminder(index);
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}