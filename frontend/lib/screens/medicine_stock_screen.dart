
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/healthcare_owner_service.dart';

class MedicineStockScreen extends StatefulWidget {
  const MedicineStockScreen({super.key});

  @override
  State<MedicineStockScreen> createState() =>
      _MedicineStockScreenState();
}

class _MedicineStockScreenState extends State<MedicineStockScreen> {
  final TextEditingController medicineController =
      TextEditingController();
  final TextEditingController quantityController =
      TextEditingController();

  DateTime? selectedExpiryDate;
  String? dataOwnerUid;
  String? ownerError;

  bool isLoadingOwner = true;
  bool isSaving = false;

  User? get currentUser => FirebaseAuth.instance.currentUser;

  CollectionReference<Map<String, dynamic>> get stockCollection {
    if (dataOwnerUid == null) {
      throw StateError('Medicine stock owner is not loaded.');
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(dataOwnerUid!)
        .collection('medicine_stock');
  }

  @override
  void initState() {
    super.initState();
    loadDataOwner();
  }

  Future<void> loadDataOwner() async {
    try {
      final uid =
          await HealthcareOwnerService.getDataOwnerUid();

      if (!mounted) return;

      setState(() {
        dataOwnerUid = uid;
        ownerError = null;
        isLoadingOwner = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        ownerError =
            e.toString().replaceFirst('Exception: ', '');
        isLoadingOwner = false;
      });
    }
  }

  @override
  void dispose() {
    medicineController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  Future<void> selectExpiryDate(
    BuildContext dialogContext,
    StateSetter setDialogState,
  ) async {
    final picked = await showDatePicker(
      context: dialogContext,
      initialDate: selectedExpiryDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null && mounted) {
      setState(() {
        selectedExpiryDate = picked;
      });
      setDialogState(() {});
    }
  }

  Future<void> saveMedicineStock(
    BuildContext dialogContext,
    StateSetter setDialogState,
  ) async {
    final medicineName = medicineController.text.trim();
    final quantityText = quantityController.text.trim();

    if (medicineName.isEmpty || quantityText.isEmpty) {
      showMessage('Please enter medicine name and quantity.');
      return;
    }

    final quantity = int.tryParse(quantityText);

    if (quantity == null || quantity < 0) {
      showMessage('Please enter a valid quantity.');
      return;
    }

    if (selectedExpiryDate == null) {
      showMessage('Please select expiry date.');
      return;
    }

    if (currentUser == null || dataOwnerUid == null) {
      showMessage('Please login and load the linked account.');
      return;
    }

    setDialogState(() {
      isSaving = true;
    });

    try {
      await stockCollection.add({
        'medicineName': medicineName,
        'quantity': quantity,
        'expiryDate': Timestamp.fromDate(selectedExpiryDate!),
        'userId': dataOwnerUid,
        'createdByUid': currentUser!.uid,
        'lowStockNotified': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      medicineController.clear();
      quantityController.clear();

      setState(() {
        selectedExpiryDate = null;
      });

      Navigator.of(dialogContext).pop();
      showMessage('Medicine stock added successfully.');
    } catch (e) {
      setDialogState(() {
        isSaving = false;
      });

      showMessage('Error adding stock: $e');
    }
  }

  Future<void> updateQuantity(
    String documentId,
    int currentQuantity,
    int change,
  ) async {
    if (dataOwnerUid == null) {
      showMessage('Account details are not loaded.');
      return;
    }

    final newQuantity = currentQuantity + change;

    if (newQuantity < 0) return;

    try {
      await stockCollection.doc(documentId).update({
        'quantity': newQuantity,
        'lowStockNotified': false,
      });
    } catch (e) {
      showMessage('Unable to update stock: $e');
    }
  }

  Future<void> deleteMedicine(String documentId) async {
    if (dataOwnerUid == null) {
      showMessage('Account details are not loaded.');
      return;
    }

    try {
      await stockCollection.doc(documentId).delete();
      showMessage('Medicine deleted.');
    } catch (e) {
      showMessage('Unable to delete medicine: $e');
    }
  }

  void showAddStockDialog() {
    medicineController.clear();
    quantityController.clear();

    setState(() {
      selectedExpiryDate = null;
      isSaving = false;
    });

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Add Medicine Stock',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: medicineController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Medicine Name',
                        hintText: 'Example: Paracetamol',
                        prefixIcon: Icon(Icons.medication),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        hintText: 'Example: 10',
                        prefixIcon: Icon(Icons.inventory),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    InkWell(
                      onTap: isSaving
                          ? null
                          : () => selectExpiryDate(
                                dialogContext,
                                setDialogState,
                              ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                selectedExpiryDate == null
                                    ? 'Select Expiry Date'
                                    : '${selectedExpiryDate!.day.toString().padLeft(2, '0')}/'
                                        '${selectedExpiryDate!.month.toString().padLeft(2, '0')}/'
                                        '${selectedExpiryDate!.year}',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () => saveMedicineStock(
                            dialogContext,
                            setDialogState,
                          ),
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'No expiry date';

    final date = timestamp.toDate();

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  bool isExpired(Timestamp? timestamp) {
    if (timestamp == null) return false;

    final expiryDate = timestamp.toDate();
    final today = DateTime.now();

    final expiry = DateTime(
      expiryDate.year,
      expiryDate.month,
      expiryDate.day,
    );

    final todayDate = DateTime(
      today.year,
      today.month,
      today.day,
    );

    return expiry.isBefore(todayDate);
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Medicine Stock')),
        body: const Center(child: Text('Please login first')),
      );
    }

    if (isLoadingOwner) {
      return Scaffold(
        appBar: AppBar(title: const Text('Medicine Stock')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (dataOwnerUid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Medicine Stock')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ownerError ?? 'Unable to load account details.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isLoadingOwner = true;
                      ownerError = null;
                    });
                    loadDataOwner();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Medicine Stock',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showAddStockDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Medicine'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stockCollection
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error loading stock:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final documents = snapshot.data?.docs ?? [];

          if (documents.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 15),
                  Text(
                    'No medicine stock added',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('Tap + Add Medicine to add stock'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final doc = documents[index];
              final data = doc.data();

              final medicineName =
                  data['medicineName']?.toString() ??
                      'Unknown Medicine';

              final quantityValue = data['quantity'];
              final quantity = quantityValue is num
                  ? quantityValue.toInt()
                  : int.tryParse('$quantityValue') ?? 0;

              final expiryDate = data['expiryDate'] is Timestamp
                  ? data['expiryDate'] as Timestamp
                  : null;

              final lowStock = quantity <= 5;
              final expired = isExpired(expiryDate);

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.blue.shade50,
                            ),
                            child: const Icon(
                              Icons.medication,
                              size: 30,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  medicineName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Expiry: ${formatDate(expiryDate)}',
                                  style: TextStyle(
                                    color: expired
                                        ? Colors.red
                                        : Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 5,
                                  crossAxisAlignment:
                                      WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      'Stock: $quantity',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: lowStock
                                            ? Colors.red
                                            : Colors.green,
                                      ),
                                    ),
                                    if (lowStock)
                                      _statusLabel(
                                        'Low Stock',
                                        Colors.red,
                                      ),
                                    if (expired)
                                      _statusLabel(
                                        'Expired',
                                        Colors.red,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'delete') {
                                deleteMedicine(doc.id);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Delete'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 25),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: quantity > 0
                                ? () => updateQuantity(
                                      doc.id,
                                      quantity,
                                      -1,
                                    )
                                : null,
                            icon: const Icon(
                              Icons.remove_circle,
                              size: 32,
                            ),
                          ),
                          Container(
                            width: 70,
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$quantity',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => updateQuantity(
                              doc.id,
                              quantity,
                              1,
                            ),
                            icon: const Icon(
                              Icons.add_circle,
                              size: 32,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _statusLabel(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
