import 'package:flutter/material.dart';

class MedicineStockScreen extends StatefulWidget {
  const MedicineStockScreen({super.key});

  @override
  State<MedicineStockScreen> createState() => _MedicineStockScreenState();
}

class _MedicineStockScreenState extends State<MedicineStockScreen> {
  final TextEditingController medicineController =
      TextEditingController();

  final TextEditingController stockController =
      TextEditingController();

  final List<String> medicineSuggestions = [
    'Paracetamol Tablet',
    'Pantoprazole Tablet',
    'Amoxicillin Tablet',
    'Aspirin Tablet',
    'Cetirizine Tablet',
    'Ibuprofen Tablet',
    'Metformin Tablet',
  ];

  final List<Map<String, dynamic>> medicines = [];

  @override
  void dispose() {
    medicineController.dispose();
    stockController.dispose();
    super.dispose();
  }

  void addMedicine() {
    final name = medicineController.text.trim();
    final stockText = stockController.text.trim();

    if (name.isEmpty || stockText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter medicine name and stock.'),
        ),
      );
      return;
    }

    final stock = int.tryParse(stockText);

    if (stock == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid stock number.'),
        ),
      );
      return;
    }

    setState(() {
      medicines.add({
        'name': name,
        'stock': stock,
      });
    });

    medicineController.clear();
    stockController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Medicine stock added successfully!'),
      ),
    );
  }

  void deleteMedicine(int index) {
    setState(() {
      medicines.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Stock'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Medicine Stock',
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
                  (medicine) => medicine
                      .toLowerCase()
                      .contains(value.text.toLowerCase()),
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
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onChanged: (value) {
                    medicineController.text = value;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Medicine Name',
                    hintText: 'Type medicine name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.medication),
                  ),
                );
              },
            ),

            const SizedBox(height: 15),

            TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Stock Quantity',
                hintText: 'Example: 20',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory_2),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: addMedicine,
                icon: const Icon(Icons.add),
                label: const Text('Add Stock'),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'Medicine Stock List',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            if (medicines.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(
                    Icons.inventory_2,
                    color: Colors.orange,
                  ),
                  title: Text('No medicines added'),
                  subtitle: Text(
                    'Add medicine and stock quantity above',
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: medicines.length,
                itemBuilder: (context, index) {
                  final medicine = medicines[index];
                  final int stock = medicine['stock'];

                  final bool isLowStock = stock <= 5;

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(
                        Icons.medication,
                        color: isLowStock
                            ? Colors.red
                            : Colors.blue,
                        size: 40,
                      ),

                      title: Text(
                        medicine['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 5),

                          Text(
                            'Stock: $stock tablets',
                          ),

                          if (isLowStock)
                            const Padding(
                              padding: EdgeInsets.only(top: 5),
                              child: Text(
                                '⚠ Low Stock',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),

                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          deleteMedicine(index);
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