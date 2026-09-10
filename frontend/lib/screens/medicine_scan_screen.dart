import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class MedicineScanScreen extends StatefulWidget {
  const MedicineScanScreen({super.key});

  @override
  State<MedicineScanScreen> createState() => _MedicineScanScreenState();
}

class _MedicineScanScreenState extends State<MedicineScanScreen> {
  final ImagePicker _picker = ImagePicker();

  String scannedText = '';
  bool isScanning = false;

  Future<void> scanMedicine() async {
    try {
      setState(() {
        isScanning = true;
        scannedText = '';
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

      final inputImage = InputImage.fromFile(File(image.path));

      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );

      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      await textRecognizer.close();

      setState(() {
        scannedText = recognizedText.text;
        isScanning = false;
      });
    } catch (e) {
      setState(() {
        isScanning = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to scan medicine: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan & Verify Medicine'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.medication,
              size: 80,
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
              'Take a clear photo of the medicine strip or box to read the medicine name.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isScanning ? null : scanMedicine,
                icon: const Icon(Icons.camera_alt),
                label: Text(
                  isScanning ? 'Scanning...' : 'Open Camera',
                ),
              ),
            ),

            const SizedBox(height: 30),

            if (scannedText.isNotEmpty) ...[
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

              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      scannedText,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}