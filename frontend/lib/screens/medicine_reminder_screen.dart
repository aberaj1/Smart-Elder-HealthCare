import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

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

  final ImagePicker picker = ImagePicker();

  File? selectedImage;
  bool isScanning = false;

  final List<String> medicineSuggestions = [
    'Paracetamol Tablet',
    'Pantoprazole Tablet',
    'Amoxicillin Tablet',
    'Aspirin Tablet',
    'Cetirizine Tablet',
    'Ibuprofen Tablet',
    'Metformin Tablet',
  ];

  final List<Map<String, String>> reminders = [];

  @override
  void dispose() {
    medicineController.dispose();
    timeController.dispose();
    super.dispose();
  }

  Future<void> scanMedicine() async {
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
      );

      if (image == null) {
        return;
      }

      setState(() {
        selectedImage = File(image.path);
        isScanning = true;
      });

      final inputImage = InputImage.fromFilePath(
        image.path,
      );

      final textRecognizer =
          TextRecognizer(script: TextRecognitionScript.latin);

      final RecognizedText recognizedText =
          await textRecognizer.processImage(
        inputImage,
      );

      await textRecognizer.close();

      if (!mounted) return;

      final String scannedText =
          recognizedText.text.trim();

      if (scannedText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No text detected. Please try again.',
            ),
          ),
        );
      } else {
        setState(() {
          // First detected text will be shown
          medicineController.text = scannedText;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Medicine text scanned successfully!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'OCR scan failed: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isScanning = false;
        });
      }
    }
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

    setState(() {
      reminders.add({
        'medicine': medicine,
        'time': time,
      });

      reminderNotifier.value =
          List<Map<String, String>>.from(reminders);
    });

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
    setState(() {
      reminders.removeAt(index);

      reminderNotifier.value =
          List<Map<String, String>>.from(reminders);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reminder deleted.'),
      ),
    );
  }

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

            // Scan Medicine Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: isScanning
                    ? null
                    : scanMedicine,
                icon: isScanning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.document_scanner),
                label: Text(
                  isScanning
                      ? 'Scanning Medicine...'
                      : 'Scan Medicine',
                ),
              ),
            ),

            const SizedBox(height: 15),

            // Show selected image
            if (selectedImage != null)
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(10),
                child: Image.file(
                  selectedImage!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            if (selectedImage != null)
              const SizedBox(height: 15),

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
                // Keep autocomplete controller
                if (medicineController.text.isNotEmpty &&
                    controller.text.isEmpty) {
                  controller.text =
                      medicineController.text;
                }

                return TextField(
                  controller: controller,
                  focusNode: focusNode,

                  onChanged: (value) {
                    medicineController.text =
                        value;
                  },

                  decoration:
                      const InputDecoration(
                    labelText: 'Medicine Name',
                    hintText:
                        'Type or scan medicine name',
                    border:
                        OutlineInputBorder(),
                    prefixIcon:
                        Icon(Icons.medication),
                  ),
                );
              },
            ),

            const SizedBox(height: 15),

            TextField(
              controller: timeController,
              readOnly: true,
              onTap: selectTime,
              decoration:
                  const InputDecoration(
                labelText: 'Medicine Time',
                hintText: 'Select time',
                border:
                    OutlineInputBorder(),
                prefixIcon:
                    Icon(Icons.access_time),
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

            if (reminders.isEmpty)
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
                    'Add medicine name and time above',
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
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Text(
                        'Time: ${reminder['time']}',
                      ),
                      trailing:
                          IconButton(
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
              ),
          ],
        ),
      ),
    );
  }
}