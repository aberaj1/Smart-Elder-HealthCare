import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class MedicineScanScreen extends StatefulWidget {
  const MedicineScanScreen({super.key});

  @override
  State<MedicineScanScreen> createState() => _MedicineScanScreenState();
}

class _MedicineScanScreenState extends State<MedicineScanScreen> {
  final ImagePicker _picker = ImagePicker();

  String scannedText = '';
  String medicineName = '';
  String medicineStrength = '';

  String verificationMessage = '';
  bool? isMedicineCorrect;

  bool isScanning = false;
  bool isVerifying = false;

  // --------------------------------------------------
  // SCAN MEDICINE
  // --------------------------------------------------

  Future<void> scanMedicine() async {
    try {
      setState(() {
        isScanning = true;
        scannedText = '';
        medicineName = '';
        medicineStrength = '';
        verificationMessage = '';
        isMedicineCorrect = null;
      });

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );

      if (image == null) {
        setState(() {
          isScanning = false;
        });
        return;
      }

      final inputImage = InputImage.fromFile(
        File(image.path),
      );

      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );

      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      await textRecognizer.close();

      final text = recognizedText.text.trim();

      if (text.isEmpty) {
        setState(() {
          scannedText = 'No text detected.';
          isScanning = false;
        });
        return;
      }

      // Find medicine and strength from OCR
      final detectedMedicine = await findMedicineFromFirestore(text);
      final detectedStrength = findStrength(text);

      setState(() {
        scannedText = text;
        medicineName = detectedMedicine;
        medicineStrength = detectedStrength;
        isScanning = false;
      });

      // Verify with Firestore
      await verifyMedicine(
        detectedMedicine,
        detectedStrength,
      );
    } catch (e) {
      setState(() {
        isScanning = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to scan medicine: $e',
          ),
        ),
      );
    }
  }

  // --------------------------------------------------
  // FIND MEDICINE FROM FIRESTORE
  // --------------------------------------------------

  Future<String> findMedicineFromFirestore(
    String ocrText,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return 'Please login again';
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('medicine_reminders')
        .get();

    final normalizedOCR = normalizeText(ocrText);

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final medicine =
          data['medicine']?.toString() ?? '';

      if (medicine.isEmpty) {
        continue;
      }

      final normalizedMedicine =
          normalizeText(medicine);

      if (normalizedOCR.contains(normalizedMedicine)) {
        return medicine;
      }
    }

    return 'Medicine not recognized';
  }

  // --------------------------------------------------
  // FIND STRENGTH
  // --------------------------------------------------

  String findStrength(String text) {
    final regex = RegExp(
      r'\b(\d+(?:\.\d+)?)\s*(mg|mcg|g|ml|%|iu)\b',
      caseSensitive: false,
    );

    final match = regex.firstMatch(text);

    if (match == null) {
      return '';
    }

    return '${match.group(1)} ${match.group(2)!.toLowerCase()}';
  }

  // --------------------------------------------------
  // VERIFY MEDICINE
  // --------------------------------------------------

  Future<void> verifyMedicine(
    String detectedMedicine,
    String detectedStrength,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    setState(() {
      isVerifying = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('medicine_reminders')
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          verificationMessage =
              'No medicine schedule found. Please add a medicine reminder first.';
          isMedicineCorrect = null;
          isVerifying = false;
        });
        return;
      }

      bool medicineMatched = false;

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final scheduledMedicine =
            data['medicine']?.toString() ?? '';

        final scheduledStrength =
            data['strength']?.toString() ?? '';

        if (scheduledMedicine.isEmpty) {
          continue;
        }

        final medicineMatch =
            normalizeText(detectedMedicine) ==
            normalizeText(scheduledMedicine);

        final strengthMatch =
            normalizeStrength(detectedStrength) ==
            normalizeStrength(scheduledStrength);

        if (medicineMatch &&
            (scheduledStrength.isEmpty ||
                strengthMatch)) {
          medicineMatched = true;
          break;
        }
      }

      if (!mounted) return;

      setState(() {
        isMedicineCorrect = medicineMatched;
        isVerifying = false;

        if (medicineMatched) {
          verificationMessage =
              'This medicine matches your saved medicine schedule.';
        } else {
          verificationMessage =
              'This medicine does not match your saved medicine schedule. Please check before taking it.';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isVerifying = false;
        verificationMessage =
            'Unable to verify medicine. Please try again.';
        isMedicineCorrect = null;
      });
    }
  }

  // --------------------------------------------------
  // NORMALIZE TEXT
  // --------------------------------------------------

  String normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(
          RegExp(r'[^a-z0-9\s]'),
          ' ',
        )
        .replaceAll(
          RegExp(r'\s+'),
          ' ',
        )
        .trim();
  }

  // --------------------------------------------------
  // NORMALIZE STRENGTH
  // --------------------------------------------------

  String normalizeStrength(String text) {
    return text
        .toLowerCase()
        .replaceAll(
          RegExp(r'\s+'),
          '',
        )
        .trim();
  }

  // --------------------------------------------------
  // UI
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bool medicineFound =
        medicineName.isNotEmpty &&
        medicineName != 'Medicine not recognized';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scan & Verify Medicine',
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.medication,
              size: 80,
              color: Colors.blue,
            ),

            const SizedBox(height: 20),

            const Text(
              'Scan Medicine',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Scan the medicine strip or box clearly to verify your medicine.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed:
                    isScanning ? null : scanMedicine,
                icon: const Icon(
                  Icons.camera_alt,
                ),
                label: Text(
                  isScanning
                      ? 'Scanning...'
                      : 'Scan Medicine',
                  style: const TextStyle(
                    fontSize: 17,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            if (isScanning)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text(
                    'Reading medicine details...',
                  ),
                ],
              ),

            // --------------------------------------------------
            // MEDICINE RESULT
            // --------------------------------------------------

            if (!isScanning &&
                medicineName.isNotEmpty)
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.medication,
                            color: Colors.blue,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Medicine Detected',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'Medicine Name',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        medicineName,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: medicineFound
                              ? Colors.black
                              : Colors.orange,
                        ),
                      ),

                      if (medicineStrength.isNotEmpty) ...[
                        const SizedBox(height: 18),

                        const Text(
                          'Strength',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          medicineStrength,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      if (isVerifying)
                        const Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 10),
                              Text(
                                'Verifying medicine...',
                              ),
                            ],
                          ),
                        ),

                      if (!isVerifying &&
                          isMedicineCorrect == true)
                        Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green
                                .withOpacity(0.12),
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 32,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'CORRECT MEDICINE\n'
                                  'This medicine matches your schedule.',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (!isVerifying &&
                          isMedicineCorrect == false)
                        Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red
                                .withOpacity(0.12),
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.cancel,
                                color: Colors.red,
                                size: 32,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'WRONG MEDICINE\n'
                                  'Please check your medicine before taking it.',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (!isVerifying &&
                          isMedicineCorrect == null &&
                          verificationMessage.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange
                                .withOpacity(0.12),
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          child: Text(
                            verificationMessage,
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            // --------------------------------------------------
            // DETECTED TEXT
            // --------------------------------------------------

            if (!isScanning &&
                scannedText.isNotEmpty) ...[
              const SizedBox(height: 20),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Detected Text',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Container(
                width: double.infinity,
                constraints:
                    const BoxConstraints(
                  maxHeight: 200,
                ),
                padding:
                    const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                  ),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    scannedText,
                    style: const TextStyle(
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}