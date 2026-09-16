import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DoctorAppointmentScreen extends StatefulWidget {
  const DoctorAppointmentScreen({super.key});

  @override
  State<DoctorAppointmentScreen> createState() =>
      _DoctorAppointmentScreenState();
}

class _DoctorAppointmentScreenState
    extends State<DoctorAppointmentScreen> {
  final TextEditingController doctorController =
      TextEditingController();

  final TextEditingController specializationController =
      TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  bool isSaving = false;

  User? get currentUser => FirebaseAuth.instance.currentUser;

  CollectionReference<Map<String, dynamic>> get appointmentCollection {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('appointments');
  }

  @override
  void dispose() {
    doctorController.dispose();
    specializationController.dispose();
    super.dispose();
  }

  Future<void> selectDate() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
    );

    if (date != null) {
      setState(() {
        selectedDate = date;
      });
    }
  }

  Future<void> selectTime() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        selectedTime = time;
      });
    }
  }

  Future<void> addAppointment() async {
    final doctor = doctorController.text.trim();
    final specialization =
        specializationController.text.trim();

    if (doctor.isEmpty ||
        specialization.isEmpty ||
        selectedDate == null ||
        selectedTime == null) {
      showMessage('Please enter all appointment details.');
      return;
    }

    if (currentUser == null) {
      showMessage('Please login first.');
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await appointmentCollection.add({
        'doctor': doctor,
        'specialization': specialization,
        'date': Timestamp.fromDate(selectedDate!),
        'timeHour': selectedTime!.hour,
        'timeMinute': selectedTime!.minute,
        'time': selectedTime!.format(context),
        'userId': currentUser!.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      doctorController.clear();
      specializationController.clear();

      setState(() {
        selectedDate = null;
        selectedTime = null;
        isSaving = false;
      });

      showMessage('Appointment added successfully!');
    } catch (e) {
      setState(() {
        isSaving = false;
      });

      showMessage('Error adding appointment: $e');
    }
  }

  Future<void> deleteAppointment(String documentId) async {
    try {
      await appointmentCollection.doc(documentId).delete();

      showMessage('Appointment deleted');
    } catch (e) {
      showMessage('Unable to delete appointment');
    }
  }

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'No date';
    }

    final date = timestamp.toDate();

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Doctor Appointments'),
        ),
        body: const Center(
          child: Text('Please login first'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Doctor Appointments',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Book Doctor Appointment',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: doctorController,
              decoration: const InputDecoration(
                labelText: 'Doctor Name',
                hintText: 'Example: Dr. Kumar',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: specializationController,
              decoration: const InputDecoration(
                labelText: 'Specialization',
                hintText: 'Example: Cardiologist',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_hospital),
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: selectDate,
                icon: const Icon(Icons.calendar_month),
                label: Text(
                  selectedDate == null
                      ? 'Select Appointment Date'
                      : 'Date: ${selectedDate!.day}/'
                          '${selectedDate!.month}/'
                          '${selectedDate!.year}',
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: selectTime,
                icon: const Icon(Icons.access_time),
                label: Text(
                  selectedTime == null
                      ? 'Select Appointment Time'
                      : 'Time: ${selectedTime!.format(context)}',
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : addAppointment,
                icon: isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.add),
                label: Text(
                  isSaving
                      ? 'Saving...'
                      : 'Add Appointment',
                ),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'My Appointments',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: appointmentCollection
                  .orderBy(
                    'date',
                    descending: false,
                  )
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Error loading appointments:\n'
                        '${snapshot.error}',
                      ),
                    ),
                  );
                }

                final documents =
                    snapshot.data?.docs ?? [];

                if (documents.isEmpty) {
                  return const Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.calendar_month,
                        color: Colors.green,
                        size: 35,
                      ),
                      title: Text(
                        'No appointments added',
                      ),
                      subtitle: Text(
                        'Add your doctor appointment above',
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics:
                      const NeverScrollableScrollPhysics(),
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    final doc = documents[index];
                    final data = doc.data();

                    final doctor =
                        data['doctor'] ?? 'Unknown Doctor';

                    final specialization =
                        data['specialization'] ?? '';

                    final date =
                        data['date'] as Timestamp?;

                    final time =
                        data['time'] ?? 'No time';

                    return Card(
                      elevation: 3,
                      margin:
                          const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.all(12),

                        leading: const Icon(
                          Icons.local_hospital,
                          color: Colors.green,
                          size: 40,
                        ),

                        title: Text(
                          doctor,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        subtitle: Padding(
                          padding:
                              const EdgeInsets.only(top: 6),
                          child: Text(
                            '$specialization\n'
                            'Date: ${formatDate(date)}\n'
                            'Time: $time',
                          ),
                        ),

                        isThreeLine: true,

                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            deleteAppointment(doc.id);
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