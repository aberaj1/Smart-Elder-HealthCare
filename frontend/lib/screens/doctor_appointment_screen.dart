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

  final List<Map<String, String>> appointments = [];

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
      lastDate: DateTime(2030),
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

  void addAppointment() {
    final doctor = doctorController.text.trim();
    final specialization =
        specializationController.text.trim();

    if (doctor.isEmpty ||
        specialization.isEmpty ||
        selectedDate == null ||
        selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter all appointment details.',
          ),
        ),
      );
      return;
    }

    setState(() {
      appointments.add({
        'doctor': doctor,
        'specialization': specialization,
        'date':
            '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
        'time': selectedTime!.format(context),
      });
    });

    doctorController.clear();
    specializationController.clear();

    setState(() {
      selectedDate = null;
      selectedTime = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Appointment added successfully!',
        ),
      ),
    );
  }

  void deleteAppointment(int index) {
    setState(() {
      appointments.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Appointments'),
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
                      : 'Date: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
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
                onPressed: addAppointment,
                icon: const Icon(Icons.add),
                label: const Text('Add Appointment'),
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

            if (appointments.isEmpty)
              const Card(
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
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                itemCount: appointments.length,
                itemBuilder: (context, index) {
                  final appointment =
                      appointments[index];

                  return Card(
                    elevation: 3,
                    margin:
                        const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(
                        Icons.local_hospital,
                        color: Colors.green,
                        size: 40,
                      ),

                      title: Text(
                        appointment['doctor']!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      subtitle: Text(
                        '${appointment['specialization']}\n'
                        'Date: ${appointment['date']}\n'
                        'Time: ${appointment['time']}',
                      ),

                      isThreeLine: true,

                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          deleteAppointment(index);
                        },
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}