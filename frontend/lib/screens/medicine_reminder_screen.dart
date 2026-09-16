import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final ValueNotifier<List<Map<String, String>>> reminderNotifier =
    ValueNotifier<List<Map<String, String>>>([]);

class MedicineReminderScreen extends StatefulWidget {
  const MedicineReminderScreen({super.key});

  @override
  State<MedicineReminderScreen> createState() =>
      _MedicineReminderScreenState();
}

class _MedicineReminderScreenState
    extends State<MedicineReminderScreen> {
  final TextEditingController medicineController =
      TextEditingController();

  final TextEditingController strengthController =
      TextEditingController();

  final TextEditingController timeController =
      TextEditingController();

  final List<String> medicineSuggestions = [
    'Paracetamol',
    'Pantoprazole',
    'Amoxicillin',
    'Aspirin',
    'Cetirizine',
    'Ibuprofen',
    'Metformin',
    'Amlodipine',
    'Atorvastatin',
    'Losartan',
    'Telmisartan',
    'Omeprazole',
  ];

  final List<Map<String, String>> reminders = [];

  bool isLoading = true;
  bool isAdding = false;

  @override
  void initState() {
    super.initState();
    loadReminders();
  }

  @override
  void dispose() {
    medicineController.dispose();
    strengthController.dispose();
    timeController.dispose();
    super.dispose();
  }

  // ================= LOAD REMINDERS =================

  Future<void> loadReminders() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (!mounted) return;

        setState(() {
          isLoading = false;
        });

        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('medicine_reminders')
          .orderBy('createdAt', descending: false)
          .get();

      final loadedReminders = <Map<String, String>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        loadedReminders.add({
          'id': doc.id,
          'medicine': data['medicine']?.toString() ?? '',
          'strength': data['strength']?.toString() ?? '',
          'time': data['time']?.toString() ?? '',
          'status': data['status']?.toString() ?? 'Pending',
        });
      }

      if (!mounted) return;

      setState(() {
        reminders.clear();
        reminders.addAll(loadedReminders);
        isLoading = false;
      });

      reminderNotifier.value =
          List<Map<String, String>>.from(reminders);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load reminders: $e',
          ),
        ),
      );
    }
  }

  // ================= ADD REMINDER =================

  Future<void> addReminder() async {
    final medicine = medicineController.text.trim();
    final strength = strengthController.text.trim();
    final time = timeController.text.trim();

    if (medicine.isEmpty ||
        strength.isEmpty ||
        time.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter medicine name, strength and time.',
          ),
        ),
      );

      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please login again.',
          ),
        ),
      );

      return;
    }

    try {
      setState(() {
        isAdding = true;
      });

      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('medicine_reminders')
          .add({
        'medicine': medicine,
        'strength': strength,
        'time': time,
        'status': 'Pending',
        'statusUpdatedAt': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        reminders.add({
          'id': docRef.id,
          'medicine': medicine,
          'strength': strength,
          'time': time,
          'status': 'Pending',
        });

        reminderNotifier.value =
            List<Map<String, String>>.from(reminders);

        isAdding = false;
      });

      medicineController.clear();
      strengthController.clear();
      timeController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Medicine reminder saved successfully!',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isAdding = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to save reminder: $e',
          ),
        ),
      );
    }
  }

  // ================= UPDATE MEDICINE STATUS =================

  Future<void> updateMedicineStatus(
    int index,
    String status,
  ) async {
    final reminder = reminders[index];
    final id = reminder['id'];

    if (id == null || id.isEmpty) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('medicine_reminders')
          .doc(id)
          .update({
        'status': status,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        reminders[index]['status'] = status;

        reminderNotifier.value =
            List<Map<String, String>>.from(reminders);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${reminder['medicine']} marked as $status.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to update medicine status: $e',
          ),
        ),
      );
    }
  }

  // ================= DELETE REMINDER =================

  Future<void> deleteReminder(int index) async {
    final reminder = reminders[index];
    final id = reminder['id'];

    if (id == null || id.isEmpty) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('medicine_reminders')
          .doc(id)
          .delete();

      if (!mounted) return;

      setState(() {
        reminders.removeAt(index);

        reminderNotifier.value =
            List<Map<String, String>>.from(reminders);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Reminder deleted successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to delete reminder: $e',
          ),
        ),
      );
    }
  }

  // ================= SELECT TIME =================

  Future<void> selectTime() async {
    final TimeOfDay? selectedTime =
        await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (selectedTime != null) {
      setState(() {
        timeController.text =
            selectedTime.format(context);
      });
    }
  }

  // ================= STATUS COLOR =================

  Color getStatusColor(String status) {
    if (status == 'Taken') {
      return Colors.green;
    }

    if (status == 'Missed') {
      return Colors.red;
    }

    return Colors.orange;
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Medicine Reminder',
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
            const Text(
              'Add Medicine',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // Medicine Name
            Autocomplete<String>(
              optionsBuilder:
                  (TextEditingValue value) {
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
                if (medicineController.text.isNotEmpty &&
                    controller.text.isEmpty) {
                  controller.text =
                      medicineController.text;
                }

                return TextField(
                  controller: controller,
                  focusNode: focusNode,

                  onChanged: (value) {
                    medicineController.text = value;
                  },

                  decoration:
                      const InputDecoration(
                    labelText: 'Medicine Name',
                    hintText:
                        'Enter medicine name',
                    border:
                        OutlineInputBorder(),
                    prefixIcon:
                        Icon(Icons.medication),
                  ),
                );
              },
            ),

            const SizedBox(height: 15),

            // Strength
            TextField(
              controller: strengthController,
              keyboardType:
                  TextInputType.text,
              decoration:
                  const InputDecoration(
                labelText: 'Strength',
                hintText:
                    'Example: 500 mg',
                border:
                    OutlineInputBorder(),
                prefixIcon:
                    Icon(Icons.science),
              ),
            ),

            const SizedBox(height: 15),

            // Time
            TextField(
              controller: timeController,
              readOnly: true,
              onTap: selectTime,
              decoration:
                  const InputDecoration(
                labelText: 'Medicine Time',
                hintText:
                    'Select time',
                border:
                    OutlineInputBorder(),
                prefixIcon:
                    Icon(Icons.access_time),
              ),
            ),

            const SizedBox(height: 20),

            // Add Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed:
                    isAdding ? null : addReminder,
                icon: isAdding
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add),
                label: Text(
                  isAdding
                      ? 'Saving...'
                      : 'Add Reminder',
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

            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child:
                      CircularProgressIndicator(),
                ),
              )
            else if (reminders.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(
                    Icons.alarm,
                    color: Colors.blue,
                  ),
                  title: Text(
                    'No reminders added',
                  ),
                  subtitle: Text(
                    'Add medicine name, strength and time above',
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                itemCount: reminders.length,
                itemBuilder:
                    (context, index) {
                  final reminder =
                      reminders[index];

                  final status =
                      reminder['status'] ??
                          'Pending';

                  final statusColor =
                      getStatusColor(status);

                  return Card(
                    elevation: 3,
                    margin:
                        const EdgeInsets.only(
                      bottom: 12,
                    ),
                    child: Padding(
                      padding:
                          const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding:
                                EdgeInsets.zero,

                            leading:
                                const Icon(
                              Icons.medication,
                              color: Colors.blue,
                              size: 40,
                            ),

                            title: Text(
                              reminder['medicine'] ??
                                  '',
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),

                            subtitle: Text(
                              'Strength: ${reminder['strength'] ?? ''}\n'
                              'Time: ${reminder['time'] ?? ''}',
                            ),

                            isThreeLine: true,

                            trailing:
                                IconButton(
                              icon:
                                  const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                deleteReminder(
                                    index);
                              },
                            ),
                          ),

                          const Divider(),

                          // Status
                          Row(
                            children: [
                              const Text(
                                'Status: ',
                                style:
                                    TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              Container(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration:
                                    BoxDecoration(
                                  color: statusColor
                                      .withOpacity(
                                          0.1),
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                              20),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color:
                                        statusColor,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Taken / Missed
                          Row(
                            children: [
                              Expanded(
                                child:
                                    ElevatedButton
                                        .icon(
                                  onPressed: () {
                                    updateMedicineStatus(
                                      index,
                                      'Taken',
                                    );
                                  },
                                  icon:
                                      const Icon(
                                    Icons.check,
                                    size: 18,
                                  ),
                                  label:
                                      const Text(
                                    'Taken',
                                  ),
                                  style:
                                      ElevatedButton
                                          .styleFrom(
                                    backgroundColor:
                                        Colors.green,
                                    foregroundColor:
                                        Colors.white,
                                  ),
                                ),
                              ),

                              const SizedBox(
                                width: 10,
                              ),

                              Expanded(
                                child:
                                    ElevatedButton
                                        .icon(
                                  onPressed: () {
                                    updateMedicineStatus(
                                      index,
                                      'Missed',
                                    );
                                  },
                                  icon:
                                      const Icon(
                                    Icons.close,
                                    size: 18,
                                  ),
                                  label:
                                      const Text(
                                    'Missed',
                                  ),
                                  style:
                                      ElevatedButton
                                          .styleFrom(
                                    backgroundColor:
                                        Colors.red,
                                    foregroundColor:
                                        Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}