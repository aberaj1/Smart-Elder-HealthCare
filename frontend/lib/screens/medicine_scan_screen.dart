import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class MedicineScanScreen extends StatefulWidget {
  const MedicineScanScreen({super.key});

  @override
  State<MedicineScanScreen> createState() =>
      _MedicineScanScreenState();
}

class _MedicineScanScreenState
    extends State<MedicineScanScreen> {
  final ImagePicker _picker = ImagePicker();

  String medicineName = '';
  String foodTiming = '';
  String verificationMessage = '';

  bool isScanning = false;
  bool? canTakeMedicine;

  // ============================================================
  // SCAN MEDICINE
  // ============================================================

  Future<void> scanMedicine() async {
    try {
      setState(() {
        isScanning = true;
        medicineName = '';
        foodTiming = '';
        verificationMessage = '';
        canTakeMedicine = null;
      });

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );

      if (image == null) {
        if (!mounted) return;

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
          await textRecognizer.processImage(
        inputImage,
      );

      await textRecognizer.close();

      final String ocrText =
          recognizedText.text.trim();

      if (ocrText.isEmpty) {
        if (!mounted) return;

        setState(() {
          isScanning = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Medicine name could not be detected. Please scan the medicine strip clearly.',
            ),
          ),
        );

        return;
      }

      // ========================================================
      // FIND MEDICINE NAME
      // ========================================================

      final detectedMedicine =
          await findMedicineName(ocrText);

      if (!mounted) return;

      if (detectedMedicine.isEmpty ||
          detectedMedicine ==
              'Medicine not recognized') {
        setState(() {
          medicineName =
              'Medicine not recognized';
          verificationMessage =
              'Medicine name could not be identified. Please scan again.';
          canTakeMedicine = false;
          foodTiming = '';
          isScanning = false;
        });

        return;
      }

      // ========================================================
      // CHECK MEDICINE + TIME
      // ========================================================

      final result =
          await checkMedicineTime(detectedMedicine);

      if (!mounted) return;

      setState(() {
        medicineName = detectedMedicine;
        foodTiming = result['foodTiming'] ?? '';
        canTakeMedicine =
            result['canTake'] ?? false;

        verificationMessage =
            canTakeMedicine == true
                ? 'You can take this medicine.'
                : 'Do not take this medicine now.';

        isScanning = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isScanning = false;
        medicineName = '';
        foodTiming = '';
        verificationMessage = '';
        canTakeMedicine = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to scan medicine: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // FIND MEDICINE NAME
  // ============================================================

  Future<String> findMedicineName(
    String ocrText,
  ) async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        final snapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('medicine_reminders')
                .get();

        final normalizedOCR =
            normalizeText(ocrText);

        String? bestMatch;
        int bestScore = 0;

        // ------------------------------------------------------
        // FIRST PRIORITY:
        // Match medicine with saved reminders
        // ------------------------------------------------------

        for (final doc in snapshot.docs) {
          final data = doc.data();

          final medicine =
              data['medicine']
                      ?.toString()
                      .trim() ??
                  '';

          if (medicine.isEmpty) {
            continue;
          }

          final normalizedMedicine =
              normalizeText(medicine);

          if (normalizedMedicine.isEmpty) {
            continue;
          }

          // Exact match
          if (normalizedOCR
              .contains(normalizedMedicine)) {
            return medicine;
          }

          // Fuzzy match
          final score =
              calculateMedicineScore(
            normalizedOCR,
            normalizedMedicine,
          );

          if (score > bestScore) {
            bestScore = score;
            bestMatch = medicine;
          }
        }

        if (bestMatch != null &&
            bestScore >= 60) {
          return bestMatch;
        }
      } catch (e) {
        // Continue with OCR fallback
      }
    }

    // ----------------------------------------------------------
    // OCR FALLBACK
    // ----------------------------------------------------------

    return extractMedicineName(ocrText);
  }

  // ============================================================
  // CHECK MEDICINE + TIME
  // ============================================================

  Future<Map<String, dynamic>>
      checkMedicineTime(
    String detectedMedicine,
  ) async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return {
        'canTake': false,
        'foodTiming': '',
      };
    }

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('medicine_reminders')
              .get();

      final detected =
          normalizeText(detectedMedicine);

      final now = DateTime.now();

      // --------------------------------------------------------
      // CHECK EVERY REMINDER
      // --------------------------------------------------------

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final scheduledMedicine =
            data['medicine']
                    ?.toString()
                    .trim() ??
                '';

        if (scheduledMedicine.isEmpty) {
          continue;
        }

        final scheduled =
            normalizeText(scheduledMedicine);

        // Medicine name must match
        bool medicineMatches = false;

        if (detected == scheduled) {
          medicineMatches = true;
        } else if (detected.contains(scheduled) ||
            scheduled.contains(detected)) {
          medicineMatches = true;
        } else {
          final score =
              calculateMedicineScore(
            detected,
            scheduled,
          );

          if (score >= 60) {
            medicineMatches = true;
          }
        }

        if (!medicineMatches) {
          continue;
        }

        // ------------------------------------------------------
        // GET FOOD TIMING
        // ------------------------------------------------------

        final savedFoodTiming =
            data['foodTiming']
                    ?.toString()
                    .trim() ??
                'Before Food';

        // ------------------------------------------------------
        // GET REMINDER HOUR/MINUTE
        // --------------------------------------------------------

        int? reminderHour;
        int? reminderMinute;

        // New format:
        // timeHour / timeMinute

        if (data['timeHour'] != null) {
          reminderHour =
              int.tryParse(
            data['timeHour'].toString(),
          );
        }

        if (data['timeMinute'] != null) {
          reminderMinute =
              int.tryParse(
            data['timeMinute'].toString(),
          );
        }

        // ------------------------------------------------------
        // If hour/minute not available,
        // try saved "time" field
        // ------------------------------------------------------

        if (reminderHour == null ||
            reminderMinute == null) {
          final savedTime =
              data['time']?.toString() ?? '';

          final parsedTime =
              parseTimeString(savedTime);

          if (parsedTime != null) {
            reminderHour = parsedTime['hour'];
            reminderMinute =
                parsedTime['minute'];
          }
        }

        // If no time found, don't allow
        if (reminderHour == null ||
            reminderMinute == null) {
          continue;
        }

        // ------------------------------------------------------
        // CREATE TODAY'S REMINDER TIME
        // ------------------------------------------------------

        final reminderDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          reminderHour,
          reminderMinute,
        );

        // ------------------------------------------------------
        // 1 HOUR BEFORE
        // ------------------------------------------------------

        final oneHourBefore =
            reminderDateTime.subtract(
          const Duration(hours: 1),
        );

        // ------------------------------------------------------
        // 1 HOUR AFTER
        // ------------------------------------------------------

        final oneHourAfter =
            reminderDateTime.add(
          const Duration(hours: 1),
        );

        // ------------------------------------------------------
        // CURRENT TIME INSIDE WINDOW?
        // ------------------------------------------------------

        if (!now.isBefore(oneHourBefore) &&
            !now.isAfter(oneHourAfter)) {
          return {
            'canTake': true,
            'foodTiming': savedFoodTiming,
          };
        }
      }

      // --------------------------------------------------------
      // Medicine exists but current time is outside reminder
      // --------------------------------------------------------

      String matchedFoodTiming = '';

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final scheduledMedicine =
            data['medicine']
                    ?.toString()
                    .trim() ??
                '';

        if (scheduledMedicine.isEmpty) {
          continue;
        }

        final scheduled =
            normalizeText(scheduledMedicine);

        if (detected == scheduled ||
            detected.contains(scheduled) ||
            scheduled.contains(detected)) {
          matchedFoodTiming =
              data['foodTiming']
                      ?.toString()
                      .trim() ??
                  'Before Food';

          break;
        }
      }

      return {
        'canTake': false,
        'foodTiming': matchedFoodTiming,
      };
    } catch (e) {
      return {
        'canTake': false,
        'foodTiming': '',
      };
    }
  }

  // ============================================================
  // PARSE TIME STRING
  // Supports:
  // 8:00 AM
  // 08:00 AM
  // 8:00
  // 20:00
  // ============================================================

  Map<String, int>? parseTimeString(
    String time,
  ) {
    if (time.trim().isEmpty) {
      return null;
    }

    final value =
        time.trim().toUpperCase();

    // ----------------------------------------------------------
    // AM / PM
    // ----------------------------------------------------------

    final amPmRegex = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
    );

    final amPmMatch =
        amPmRegex.firstMatch(value);

    if (amPmMatch != null) {
      int hour =
          int.parse(amPmMatch.group(1)!);

      final minute =
          int.parse(amPmMatch.group(2)!);

      final period =
          amPmMatch.group(3)!;

      if (period == 'PM' && hour != 12) {
        hour += 12;
      }

      if (period == 'AM' && hour == 12) {
        hour = 0;
      }

      return {
        'hour': hour,
        'minute': minute,
      };
    }

    // ----------------------------------------------------------
    // 24 HOUR FORMAT
    // ----------------------------------------------------------

    final normalRegex = RegExp(
      r'^(\d{1,2}):(\d{2})$',
    );

    final normalMatch =
        normalRegex.firstMatch(value);

    if (normalMatch != null) {
      final hour =
          int.parse(normalMatch.group(1)!);

      final minute =
          int.parse(normalMatch.group(2)!);

      if (hour >= 0 &&
          hour <= 23 &&
          minute >= 0 &&
          minute <= 59) {
        return {
          'hour': hour,
          'minute': minute,
        };
      }
    }

    return null;
  }

  // ============================================================
  // MEDICINE MATCH SCORE
  // ============================================================

  int calculateMedicineScore(
    String ocr,
    String medicine,
  ) {
    final ocrWords = ocr.split(' ');
    final medicineWords =
        medicine.split(' ');

    if (medicineWords.isEmpty) {
      return 0;
    }

    int matchedWords = 0;

    for (final medicineWord
        in medicineWords) {
      if (medicineWord.length < 3) {
        continue;
      }

      for (final ocrWord in ocrWords) {
        if (ocrWord == medicineWord) {
          matchedWords++;
          break;
        }

        // Small OCR spelling mistakes
        if (ocrWord.length >= 5 &&
            medicineWord.length >= 5) {
          final distance =
              levenshteinDistance(
            ocrWord,
            medicineWord,
          );

          final maxLength =
              ocrWord.length >
                      medicineWord.length
                  ? ocrWord.length
                  : medicineWord.length;

          if (distance <= 1 ||
              (distance <= 2 &&
                  maxLength >= 8)) {
            matchedWords++;
            break;
          }
        }
      }
    }

    if (matchedWords == 0) {
      return 0;
    }

    return ((matchedWords /
                medicineWords.length) *
            100)
        .round();
  }

  // ============================================================
  // LEVENSHTEIN DISTANCE
  // ============================================================

  int levenshteinDistance(
    String a,
    String b,
  ) {
    if (a == b) {
      return 0;
    }

    if (a.isEmpty) {
      return b.length;
    }

    if (b.isEmpty) {
      return a.length;
    }

    List<int> previous =
        List.generate(
      b.length + 1,
      (index) => index,
    );

    for (int i = 1;
        i <= a.length;
        i++) {
      final current =
          List<int>.filled(
        b.length + 1,
        0,
      );

      current[0] = i;

      for (int j = 1;
          j <= b.length;
          j++) {
        final cost =
            a[i - 1] == b[j - 1]
                ? 0
                : 1;

        current[j] = [
          current[j - 1] + 1,
          previous[j] + 1,
          previous[j - 1] + cost,
        ].reduce(
          (value, element) =>
              value < element
                  ? value
                  : element,
        );
      }

      previous = current;
    }

    return previous[b.length];
  }

  // ============================================================
  // EXTRACT MEDICINE NAME FROM OCR
  // ============================================================

  String extractMedicineName(
    String text,
  ) {
    final lines = text
        .split(RegExp(r'[\r\n]+'))
        .map(
          (line) => line.trim(),
        )
        .where(
          (line) => line.isNotEmpty,
        )
        .toList();

    if (lines.isEmpty) {
      return 'Medicine not recognized';
    }

    final ignoredWords = <String>{
      'tablet',
      'tablets',
      'tab',
      'tabs',
      'capsule',
      'capsules',
      'cap',
      'caps',
      'medicine',
      'medicines',
      'composition',
      'contains',
      'each',
      'oral',
      'use',
      'only',
      'for',
      'india',
      'limited',
      'ltd',
      'pvt',
      'pharma',
      'pharmaceuticals',
      'manufacturer',
      'manufactured',
      'mfg',
      'batch',
      'exp',
      'expiry',
      'date',
      'mrp',
      'prescription',
      'store',
      'keep',
      'away',
      'children',
      'warning',
      'ip',
      'bp',
      'usp',
      'mg',
      'mcg',
      'ml',
      'g',
      'iu',
    };

    final strengthRegex = RegExp(
      r'\b\d+(?:\.\d+)?\s*(?:mg|mcg|g|ml|%|iu)\b',
      caseSensitive: false,
    );

    final candidates = <String>[];

    for (final line in lines) {
      String cleaned = line;

      // Remove strength
      cleaned = cleaned.replaceAll(
        strengthRegex,
        ' ',
      );

      // Remove numbers
      cleaned = cleaned.replaceAll(
        RegExp(r'\b\d+\b'),
        ' ',
      );

      // Remove symbols
      cleaned = cleaned.replaceAll(
        RegExp(r'[^a-zA-Z\s]'),
        ' ',
      );

      // Remove extra spaces
      cleaned = cleaned.replaceAll(
        RegExp(r'\s+'),
        ' ',
      ).trim();

      if (cleaned.isEmpty) {
        continue;
      }

      final words =
          cleaned.split(' ');

      final usefulWords =
          words.where((word) {
        final lower =
            word.toLowerCase().trim();

        if (lower.length < 3) {
          return false;
        }

        if (ignoredWords
            .contains(lower)) {
          return false;
        }

        return true;
      }).toList();

      if (usefulWords.isEmpty) {
        continue;
      }

      final candidate =
          usefulWords.join(' ').trim();

      if (candidate.isNotEmpty) {
        candidates.add(candidate);
      }
    }

    if (candidates.isEmpty) {
      return 'Medicine not recognized';
    }

    candidates.sort((a, b) {
      final aWords =
          a.split(' ').length;
      final bWords =
          b.split(' ').length;

      if (aWords != bWords) {
        return aWords.compareTo(bWords);
      }

      return a.length.compareTo(
        b.length,
      );
    });

    return candidates.first;
  }

  // ============================================================
  // NORMALIZE TEXT
  // ============================================================

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

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final bool medicineFound =
        medicineName.isNotEmpty &&
        medicineName !=
            'Medicine not recognized';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Medicine Scan',
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(20),

        child: Column(
          children: [
            const SizedBox(height: 20),

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
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Scan the medicine strip clearly to identify the medicine and check the correct time.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 52,

              child:
                  ElevatedButton.icon(
                onPressed: isScanning
                    ? null
                    : scanMedicine,

                icon: const Icon(
                  Icons.camera_alt,
                ),

                label: Text(
                  isScanning
                      ? 'Scanning...'
                      : 'Scan Medicine',
                  style:
                      const TextStyle(
                    fontSize: 17,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ==================================================
            // SCANNING
            // ==================================================

            if (isScanning)
              const Column(
                children: [
                  CircularProgressIndicator(),

                  SizedBox(height: 15),

                  Text(
                    'Identifying medicine...',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),

            // ==================================================
            // RESULT
            // ==================================================

            if (!isScanning &&
                medicineFound)
              Card(
                elevation: 4,

                child: Padding(
                  padding:
                      const EdgeInsets.all(25),

                  child: Column(
                    children: [
                      const Icon(
                        Icons.medication,
                        size: 55,
                        color: Colors.blue,
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      const Text(
                        'Medicine Name',
                        style:
                            TextStyle(
                          fontSize: 16,
                          color:
                              Colors.grey,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      Text(
                        medicineName,
                        textAlign:
                            TextAlign.center,
                        style:
                            const TextStyle(
                          fontSize: 28,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      // ==================================================
                      // BEFORE FOOD / AFTER FOOD
                      // ==================================================

                      if (foodTiming
                          .isNotEmpty) ...[
                        const SizedBox(
                          height: 20,
                        ),

                        Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),

                          decoration:
                              BoxDecoration(
                            color: Colors
                                .orange
                                .shade50,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              20,
                            ),
                          ),

                          child: Text(
                            foodTiming,
                            style:
                                TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight
                                      .bold,
                              color: Colors
                                  .orange
                                  .shade800,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(
                        height: 25,
                      ),

                      // ==================================================
                      // CAN TAKE
                      // ==================================================

                      if (canTakeMedicine ==
                          true)
                        Container(
                          width:
                              double.infinity,
                          padding:
                              const EdgeInsets
                                  .all(18),

                          decoration:
                              BoxDecoration(
                            color: Colors
                                .green
                                .shade50,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                            border: Border.all(
                              color:
                                  Colors.green,
                              width: 1.5,
                            ),
                          ),

                          child: Column(
                            children: [
                              const Icon(
                                Icons
                                    .check_circle,
                                color:
                                    Colors.green,
                                size: 45,
                              ),

                              const SizedBox(
                                height: 10,
                              ),

                              const Text(
                                'You can take this medicine.',
                                textAlign:
                                    TextAlign
                                        .center,
                                style:
                                    TextStyle(
                                  color:
                                      Colors.green,
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // ==================================================
                      // DO NOT TAKE
                      // ==================================================

                      if (canTakeMedicine ==
                          false)
                        Container(
                          width:
                              double.infinity,
                          padding:
                              const EdgeInsets
                                  .all(18),

                          decoration:
                              BoxDecoration(
                            color: Colors
                                .red
                                .shade50,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                            border: Border.all(
                              color:
                                  Colors.red,
                              width: 1.5,
                            ),
                          ),

                          child: Column(
                            children: [
                              const Icon(
                                Icons.cancel,
                                color:
                                    Colors.red,
                                size: 45,
                              ),

                              const SizedBox(
                                height: 10,
                              ),

                              const Text(
                                'Do not take this medicine now.',
                                textAlign:
                                    TextAlign
                                        .center,
                                style:
                                    TextStyle(
                                  color:
                                      Colors.red,
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            // ==================================================
            // NOT RECOGNIZED
            // ==================================================

            if (!isScanning &&
                medicineName ==
                    'Medicine not recognized')
              Card(
                elevation: 3,

                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    20,
                  ),

                  child: Column(
                    children: [
                      const Icon(
                        Icons
                            .warning_amber_rounded,
                        size: 55,
                        color:
                            Colors.orange,
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      const Text(
                        'Medicine not recognized',
                        textAlign:
                            TextAlign.center,
                        style:
                            TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                          color:
                              Colors.orange,
                        ),
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      const Text(
                        'Please scan the medicine strip clearly and try again.',
                        textAlign:
                            TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(
              height: 30,
            ),
          ],
        ),
      ),
    );
  }
}