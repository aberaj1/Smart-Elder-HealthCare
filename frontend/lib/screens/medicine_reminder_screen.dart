import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/notification_service.dart';
import '../services/healthcare_owner_service.dart';

final ValueNotifier<List<Map<String, String>>> reminderNotifier =
    ValueNotifier<List<Map<String, String>>>([]);

class MedicineReminderScreen extends StatefulWidget {
  final String? initialReminderId;

  const MedicineReminderScreen({
    super.key,
    this.initialReminderId,
  });

  @override
  State<MedicineReminderScreen> createState() =>
      _MedicineReminderScreenState();
}

class _MedicineReminderScreenState
    extends State<MedicineReminderScreen> {
  final TextEditingController medicineController =
      TextEditingController();

  final TextEditingController timeController =
      TextEditingController();

  final TextEditingController quantityController =
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
  bool isCaregiver = false;

  String? dataOwnerUid;

  int? selectedHour;
  int? selectedMinute;

  String selectedFoodTiming = 'Before Food';
  DateTime? selectedExpiryDate;

  @override
  void initState() {
    super.initState();
    initializeScreen();
  }

  @override
  void dispose() {
    medicineController.dispose();
    timeController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  // INITIALIZE USER AND DATA OWNER

  Future<void> initializeScreen() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (!mounted) return;
        setState(() => isLoading = false);
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final role =
          userDoc.data()?['role']?.toString().toLowerCase() ?? '';

      final ownerUid =
          await HealthcareOwnerService.getDataOwnerUid();

      if (!mounted) return;

      setState(() {
        isCaregiver = role == 'caregiver';
        dataOwnerUid = ownerUid;
      });

      await loadReminders();
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);
      showMessage('Unable to open medicine reminders: $e');
    }
  }

  // FIRESTORE COLLECTIONS

  CollectionReference<Map<String, dynamic>> get remindersCollection {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(dataOwnerUid)
        .collection('medicine_reminders');
  }

  CollectionReference<Map<String, dynamic>> get stockCollection {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(dataOwnerUid)
        .collection('medicine_stock');
  }

  // TODAY DATE

  String getTodayKey() {
    final now = DateTime.now();

    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // LOAD MEDICINE REMINDERS

  Future<void> loadReminders() async {
    try {
      if (dataOwnerUid == null) {
        if (mounted) {
          setState(() => isLoading = false);
        }
        return;
      }

      final snapshot = await remindersCollection
          .orderBy('createdAt', descending: false)
          .get();

      final loadedReminders = <Map<String, String>>[];
      final today = getTodayKey();

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final medicine = data['medicine']?.toString() ?? '';
        final foodTiming =
            data['foodTiming']?.toString() ?? 'Before Food';
        final time = data['time']?.toString() ?? '';

        int? hour = int.tryParse(data['hour']?.toString() ?? '');
        int? minute = int.tryParse(data['minute']?.toString() ?? '');

        // Support reminders saved before hour/minute fields existed.
        if ((hour == null || minute == null) && time.isNotEmpty) {
          final parsedTime = parseTimeString(time);

          if (parsedTime != null) {
            hour = parsedTime.hour;
            minute = parsedTime.minute;
          }
        }

        String status = data['status']?.toString() ?? 'Pending';
        final statusDate = data['statusDate']?.toString() ?? '';

        // Reset status only when a previously recorded date is different.
        if (statusDate.isNotEmpty && statusDate != today) {
          status = 'Pending';

          await doc.reference.update({
            'status': 'Pending',
            'statusDate': today,
            'statusUpdatedAt': null,
          });
        }

        loadedReminders.add({
          'id': doc.id,
          'medicine': medicine,
          'foodTiming': foodTiming,
          'time': time,
          'status': status,
          'hour': hour?.toString() ?? '',
          'minute': minute?.toString() ?? '',
        });

        // Schedule the daily medicine notification.
        if (medicine.isNotEmpty && hour != null && minute != null) {
          await NotificationService.instance.scheduleMedicineNotification(
            notificationId: doc.id,
            medicine: medicine,
            foodTiming: foodTiming,
            hour: hour,
            minute: minute,
          );
        }
      }

      if (!mounted) return;

      setState(() {
        reminders
          ..clear()
          ..addAll(loadedReminders);
        isLoading = false;
      });

      reminderNotifier.value =
          List<Map<String, String>>.from(reminders);

      // Open the medicine details when navigating from a notification.
      final requestedId = widget.initialReminderId;

      if (requestedId != null && requestedId.isNotEmpty) {
        final matchingReminders = reminders.where(
          (item) => item['id'] == requestedId,
        );

        if (matchingReminders.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            showReminderDetails(matchingReminders.first);
          });
        } else {
          showMessage('The selected medicine reminder was not found.');
        }
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);
      showMessage('Unable to load reminders: $e');
    }
  }

  // PARSE TIME

  TimeOfDay? parseTimeString(String time) {
    try {
      final parts = time.trim().split(' ');

      if (parts.length != 2) return null;

      final timeParts = parts[0].split(':');

      if (timeParts.length != 2) return null;

      int hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final period = parts[1].toUpperCase();

      if (period == 'PM' && hour != 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;

      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
        return null;
      }

      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return null;
    }
  }

  // ADD MEDICINE, REMINDER AND STOCK
  // This form is available for both Elder and Caretaker.

  Future<void> addReminder() async {
    final medicine = medicineController.text.trim();
    final time = timeController.text.trim();
    final quantityText = quantityController.text.trim();
    final quantity = int.tryParse(quantityText);

    if (medicine.isEmpty || time.isEmpty || quantityText.isEmpty) {
      showMessage('Enter medicine name, time and stock quantity.');
      return;
    }

    if (quantity == null || quantity < 0) {
      showMessage('Enter a valid stock quantity.');
      return;
    }

    if (selectedExpiryDate == null) {
      showMessage('Please select medicine expiry date.');
      return;
    }

    if (selectedHour == null || selectedMinute == null) {
      showMessage('Please select medicine time.');
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null || dataOwnerUid == null) {
      showMessage('Please login again or connect an elder.');
      return;
    }

    try {
      setState(() => isAdding = true);

      // Save the reminder under the elder's account.
      final docRef = await remindersCollection.add({
        'medicine': medicine,
        'foodTiming': selectedFoodTiming,
        'time': time,
        'hour': selectedHour,
        'minute': selectedMinute,
        'status': 'Pending',
        'statusDate': getTodayKey(),
        'statusUpdatedAt': null,
        'userId': dataOwnerUid,
        'createdByUid': currentUser.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Find existing stock for this medicine.
      final stockSnapshot = await stockCollection.get();
      bool stockExists = false;

      for (final stockDoc in stockSnapshot.docs) {
        final stockData = stockDoc.data();
        final stockMedicine =
            stockData['medicineName']?.toString().trim() ?? '';

        if (stockMedicine.toLowerCase() == medicine.toLowerCase()) {
          stockExists = true;

          await stockDoc.reference.update({
            'quantity': quantity,
            'expiryDate': Timestamp.fromDate(selectedExpiryDate!),
            'lowStockNotified': false,
          });

          break;
        }
      }

      // Add stock if this medicine does not exist yet.
      if (!stockExists) {
        await stockCollection.add({
          'medicineName': medicine,
          'quantity': quantity,
          'expiryDate': Timestamp.fromDate(selectedExpiryDate!),
          'userId': dataOwnerUid,
          'lowStockNotified': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await NotificationService.instance.scheduleMedicineNotification(
        notificationId: docRef.id,
        medicine: medicine,
        foodTiming: selectedFoodTiming,
        hour: selectedHour!,
        minute: selectedMinute!,
      );

      if (!mounted) return;

      medicineController.clear();
      timeController.clear();
      quantityController.clear();

      setState(() {
        selectedHour = null;
        selectedMinute = null;
        selectedExpiryDate = null;
        selectedFoodTiming = 'Before Food';
        isAdding = false;
      });

      await loadReminders();
      showMessage('Medicine, stock and reminder saved successfully!');
    } catch (e) {
      if (!mounted) return;

      setState(() => isAdding = false);
      showMessage('Unable to save medicine: $e');
    }
  }

  // CONFIRM TAKEN OR MISSED
  // Caretakers cannot update medicine status.

  Future<void> confirmMedicineStatus(int index, String status) async {
    if (isCaregiver) return;

    final reminder = reminders[index];
    final medicineName = reminder['medicine'] ?? 'Medicine';

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            status == 'Taken'
                ? 'Confirm Medicine Taken'
                : 'Confirm Medicine Missed',
          ),
          content: Text(
            status == 'Taken'
                ? 'Did you really take $medicineName?'
                : 'Did you really miss $medicineName?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(status == 'Taken' ? 'Yes, Taken' : 'Yes, Missed'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await updateMedicineStatus(index, status);
    }
  }

  // UPDATE STATUS AND REDUCE STOCK WHEN TAKEN

  Future<void> updateMedicineStatus(int index, String status) async {
    if (isCaregiver || dataOwnerUid == null) return;

    final reminder = reminders[index];
    final id = reminder['id'];

    if (id == null || id.isEmpty) return;

    final currentStatus = reminder['status'] ?? 'Pending';

    if (status == 'Taken' && currentStatus == 'Taken') {
      showMessage('This medicine is already marked as Taken.');
      return;
    }

    try {
      await remindersCollection.doc(id).update({
        'status': status,
        'statusDate': getTodayKey(),
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      });

      if (status == 'Taken') {
        final medicineName =
            reminder['medicine']?.trim().toLowerCase() ?? '';

        if (medicineName.isNotEmpty) {
          final stockSnapshot = await stockCollection.get();

          for (final stockDoc in stockSnapshot.docs) {
            final stockData = stockDoc.data();

            final stockMedicine =
                stockData['medicineName']?.toString().trim() ?? '';

            if (stockMedicine.toLowerCase() == medicineName) {
              final currentQuantity =
                  int.tryParse(stockData['quantity']?.toString() ?? '') ?? 0;

              if (currentQuantity > 0) {
                final newQuantity = currentQuantity - 1;

                final lowStockNotified =
                    stockData['lowStockNotified'] ?? false;

                final updateData = <String, dynamic>{
                  'quantity': newQuantity,
                };

                if (newQuantity <= 5 && lowStockNotified == false) {
                  updateData['lowStockNotified'] = true;

                  await stockDoc.reference.update(updateData);

                  await NotificationService.instance.showLowStockNotification(
                    medicine: stockMedicine,
                    quantity: newQuantity,
                  );
                } else {
                  await stockDoc.reference.update(updateData);
                }
              }

              break;
            }
          }
        }
      }

      if (!mounted) return;

      setState(() {
        reminders[index]['status'] = status;
      });

      reminderNotifier.value =
          List<Map<String, String>>.from(reminders);

      showMessage('${reminder['medicine']} marked as $status.');
    } catch (e) {
      showMessage('Unable to update medicine status: $e');
    }
  }

  // DELETE REMINDER

  Future<void> deleteReminder(int index) async {
    if (dataOwnerUid == null) return;

    final reminder = reminders[index];
    final id = reminder['id'];

    if (id == null || id.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Reminder'),
          content: Text(
            'Delete ${reminder['medicine'] ?? 'this medicine'} reminder?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await NotificationService.instance.cancelNotification(id);
      await remindersCollection.doc(id).delete();

      if (!mounted) return;

      setState(() {
        reminders.removeAt(index);
      });

      reminderNotifier.value =
          List<Map<String, String>>.from(reminders);

      showMessage('Reminder deleted successfully.');
    } catch (e) {
      showMessage('Unable to delete reminder: $e');
    }
  }

  // SELECT TIME

  Future<void> selectTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (selectedTime == null || !mounted) return;

    setState(() {
      selectedHour = selectedTime.hour;
      selectedMinute = selectedTime.minute;
      timeController.text = selectedTime.format(context);
    });
  }

  // SELECT EXPIRY DATE

  Future<void> selectExpiryDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: selectedExpiryDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 20),
    );

    if (picked == null || !mounted) return;

    setState(() {
      selectedExpiryDate = picked;
    });
  }

  // STATUS COLOR

  Color getStatusColor(String status) {
    switch (status) {
      case 'Taken':
        return Colors.green;
      case 'Missed':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  // OPEN SPECIFIC REMINDER WHEN NOTIFICATION IS TAPPED

  void showReminderDetails(Map<String, String> reminder) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(reminder['medicine'] ?? 'Medicine Reminder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Time: ${reminder['time'] ?? 'Not set'}'),
              const SizedBox(height: 8),
              Text(
                'Food timing: ${reminder['foodTiming'] ?? 'Not set'}',
              ),
              const SizedBox(height: 8),
              Text('Status: ${reminder['status'] ?? 'Pending'}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // ADD MEDICINE FORM

  Widget buildAddMedicineForm() {
    return Column(
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
          optionsBuilder: (TextEditingValue value) {
            if (value.text.isEmpty) {
              return const Iterable<String>.empty();
            }

            return medicineSuggestions.where(
              (medicine) => medicine.toLowerCase().contains(
                    value.text.toLowerCase(),
                  ),
            );
          },
          onSelected: (value) {
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
              controller.text = medicineController.text;
            }

            return TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: (value) {
                medicineController.text = value;
              },
              decoration: const InputDecoration(
                labelText: 'Medicine Name',
                hintText: 'Enter medicine name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medication),
              ),
            );
          },
        ),

        const SizedBox(height: 15),

        DropdownButtonFormField<String>(
          value: selectedFoodTiming,
          decoration: const InputDecoration(
            labelText: 'Medicine Timing',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.restaurant),
          ),
          items: const [
            DropdownMenuItem(
              value: 'Before Food',
              child: Text('Before Food'),
            ),
            DropdownMenuItem(
              value: 'After Food',
              child: Text('After Food'),
            ),
            DropdownMenuItem(
              value: 'With Food',
              child: Text('With Food'),
            ),
          ],
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              selectedFoodTiming = value;
            });
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
            prefixIcon: Icon(Icons.access_time),
          ),
        ),

        const SizedBox(height: 15),

        TextField(
          controller: quantityController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Stock Quantity',
            hintText: 'Enter quantity',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.inventory_2),
          ),
        ),

        const SizedBox(height: 15),

        OutlinedButton.icon(
          onPressed: selectExpiryDate,
          icon: const Icon(Icons.calendar_month),
          label: Text(
            selectedExpiryDate == null
                ? 'Select Expiry Date'
                : 'Expiry: '
                    '${selectedExpiryDate!.day.toString().padLeft(2, '0')}/'
                    '${selectedExpiryDate!.month.toString().padLeft(2, '0')}/'
                    '${selectedExpiryDate!.year}',
          ),
        ),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: isAdding ? null : addReminder,
            icon: isAdding
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.add),
            label: Text(isAdding ? 'Saving...' : 'Add Medicine'),
          ),
        ),
      ],
    );
  }

  // MEDICINE REMINDER CARD

  Widget buildReminderCard(int index) {
    final reminder = reminders[index];
    final status = reminder['status'] ?? 'Pending';
    final statusColor = getStatusColor(status);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.medication,
                color: Colors.blue,
                size: 40,
              ),
              title: Text(
                reminder['medicine'] ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Text(
                '${reminder['foodTiming'] ?? 'Before Food'}\n'
                'Time: ${reminder['time'] ?? ''}',
              ),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'View details',
                    icon: const Icon(Icons.info_outline),
                    onPressed: () => showReminderDetails(reminder),
                  ),
                  IconButton(
                    tooltip: 'Delete reminder',
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => deleteReminder(index),
                  ),
                ],
              ),
            ),

            const Divider(),

            Row(
              children: [
                const Text(
                  'Status: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Only the elder sees Taken/Missed buttons.
            if (!isCaregiver)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: status == 'Taken'
                          ? null
                          : () => confirmMedicineStatus(index, 'Taken'),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Taken'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: status == 'Missed'
                          ? null
                          : () => confirmMedicineStatus(index, 'Missed'),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Missed'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // MAIN SCREEN

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Reminder'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadReminders,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Important: form is shown for BOTH roles.
                  buildAddMedicineForm(),

                  const SizedBox(height: 30),

                  const Text(
                    'Reminders',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  if (reminders.isEmpty)
                    const Card(
                      child: ListTile(
                        leading: Icon(
                          Icons.alarm,
                          color: Colors.blue,
                        ),
                        title: Text('No reminders added'),
                        subtitle: Text(
                          'Add medicine, timing, time and stock above.',
                        ),
                      ),
                    )
                  else
                    ...List.generate(
                      reminders.length,
                      buildReminderCard,
                    ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}