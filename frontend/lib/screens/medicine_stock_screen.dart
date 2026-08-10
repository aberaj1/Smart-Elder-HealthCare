import 'package:flutter/material.dart';

class MedicineStockScreen extends StatelessWidget {
  const MedicineStockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Stock'),
        backgroundColor: Colors.orange,
      ),
      body: const Center(
        child: Text(
          'Medicine stock management is coming soon.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
