import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_sultan/provider/city_provider.dart';

class PlantsCard extends ConsumerStatefulWidget {
  final QueryDocumentSnapshot product;
  final bool isPinVerified;
  final int index;

  const PlantsCard({
    super.key,
    required this.product,
    required this.isPinVerified,
    required this.index,
  });

  @override
  ProductCardState createState() => ProductCardState();
}

class ProductCardState extends ConsumerState<PlantsCard> {
  late TextEditingController _value1Controller;
  late TextEditingController _value2Controller;
  late TextEditingController _value3Controller;

  @override
  void initState() {
    super.initState();
    _value1Controller = TextEditingController();
    _value2Controller = TextEditingController();
    _value3Controller = TextEditingController();

    final selectedCity = ref.watch(cityProvider);

    // Fetch existing values for the product from the 'veggies_values' collection under the selected city
    FirebaseFirestore.instance
        .collection('Cities') // Cities collection
        .doc(selectedCity) // Document for the specific city (e.g., 'Lahore')
        .collection(
            'plants_values') // veggies_values collection under the city
        .doc(widget.product.id) // Document for the specific product
        .get()
        .then((documentSnapshot) {
      if (documentSnapshot.exists) {
        var data = documentSnapshot.data();
        if (data != null) {
          setState(() {
            _value1Controller.text = data['value1']?.toString() ?? '';
            _value2Controller.text = data['value2']?.toString() ?? '';
            _value3Controller.text = data['value3']?.toString() ?? '';
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _value1Controller.dispose();
    _value2Controller.dispose();
    _value3Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              '${widget.index}', // Displaying the index
              style: const TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading:
                Image.network(widget.product['url'], height: 50, width: 50),
            title: Text(widget.product['name']),
            subtitle:
                Text('${widget.isPinVerified ? widget.product['price'] : '*'}'),
            trailing: ElevatedButton(
              onPressed: () {
                _showConfirmationDialog(context);
              },
              child: const Text('Calculate'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: _value1Controller.text.isNotEmpty
                          ? Colors.green
                          : Colors.white,
                    ),
                    child: TextField(
                      controller: _value1Controller,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 30),
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        labelText: '',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                        hintText: '',
                        hintStyle: TextStyle(fontSize: 30),
                        isCollapsed: true,
                      ),
                      onChanged: (_) {
                        _autoSave();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _value2Controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Value 2',
                      border: OutlineInputBorder(),
                    ),
                    enabled: widget.isPinVerified,
                    onChanged: (_) {
                      _autoSave();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _value3Controller,
                    decoration: const InputDecoration(
                      labelText: 'Value 3',
                      border: OutlineInputBorder(),
                    ),
                    enabled: widget.isPinVerified,
                    onChanged: (_) {
                      _autoSave();
                    },
                  ),
                ),
              ],
            ),
          ),
          OverflowBar(
            alignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  _showEditDialog(context, widget.product);
                },
                child: const Text('Edit'),
              ),
              SizedBox(
                width: 10,
              ),
              ElevatedButton(
                onPressed: () {
                  _showDeleteDialog(context, widget.product.id);
                },
                child: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _autoSave() {
    final messenger = ScaffoldMessenger.of(context); // Store reference safely

    FirebaseFirestore.instance
        .collection(
            'plants_values') // Directly access the 'veggies_values' collection
        .doc(widget.product.id) // Product document with specific ID
        .set({
      'value1': _value1Controller.text,
      'value2': _value2Controller.text,
      'value3': _value3Controller.text,
    }, SetOptions(merge: true)) // Merge to avoid overwriting existing data
        .then((_) {
      if (mounted) {
        // Use the stored messenger to show a snackbar safely
        messenger.showSnackBar(const SnackBar(
          content: Text('Data saved successfully!'),
          duration: Duration(seconds: 2),
        ));
      }
    }).catchError((error) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Text('Failed to save data: $error'),
          duration: const Duration(seconds: 2),
        ));
      }
    });
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Value'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _value1Controller.text,
                style: const TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _calculateAndUpload(
                        context,
                        widget.product,
                        _value1Controller,
                        _value2Controller,
                        _value3Controller);
                  },
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _updateValue(String fieldName, String value) {
    final selectedCity =
        ref.read(cityProvider); // Use `read` for a one-time read
    final messenger =
        ScaffoldMessenger.of(context); // Store messenger reference safely

    // Update the value in the 'veggies_values' collection under the selected city
    FirebaseFirestore.instance
        .collection('Cities') // Cities collection
        .doc(selectedCity) // Document for the specific city (e.g., 'Lahore')
        .collection(
            'plants_values') // veggies_values collection under the city
        .doc(widget.product.id) // Product document with specific ID
        .update(
            {fieldName: value}) // Update the specified field with the new value
        .then((_) {
      if (mounted) {
        // Ensure the widget is still part of the tree
        messenger.showSnackBar(const SnackBar(
          content: Text('Value updated successfully'),
          duration: Duration(seconds: 2),
        ));
      }
    }).catchError((error) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Text('Failed to update value: $error'),
          duration: const Duration(seconds: 2),
        ));
      }
    });
  }

  void _calculateAndUpload(
      BuildContext context,
      QueryDocumentSnapshot product,
      TextEditingController value1Controller,
      TextEditingController value2Controller,
      TextEditingController value3Controller) {
    int value1 = int.tryParse(value1Controller.text.trim()) ?? 0;
    int value2 = int.tryParse(value2Controller.text.trim()) ?? 0;
    String value3Text = value3Controller.text.trim();
    final selectedCity = ref.watch(cityProvider);

    // If value1 is 0 or empty, result is 0
    if (value1 == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Value 1 is 0 or empty, resulting in a total of 0'),
        duration: Duration(seconds: 2),
      ));

      FirebaseFirestore.instance
          .collection('Cities') // Cities collection
          .doc(selectedCity) // Specific city document (e.g., 'Lahore')
          .collection(
              '${selectedCity}Plants') // Veggies collection under that city
          .doc(product.id) // Product document
          .update({
        'price': '0',
        'value1': value1Controller.text,
        'value2': value2Controller.text,
        'value3': value3Controller.text,
      }).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Product updated with price 0 due to Value 1 being 0 or empty'),
          duration: Duration(seconds: 2),
        ));
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update product: $error'),
          duration: const Duration(seconds: 2),
        ));
      });
      return;
    }
    int totalSum = value1 + value2;

    bool divide = value3Text.contains('/');
    bool multiply = value3Text.contains('*');

    // Handle division
    if (divide) {
      List<String> parts = value3Text.split('/');
      if (parts.length == 2) {
        double divisor = double.tryParse(parts[1]) ?? 1.0;
        if (divisor != 0.0) {
          totalSum = (totalSum ~/ divisor).toInt(); // Integer division
        }
      }
    }

    // Handle multiplication
    if (multiply) {
      List<String> parts = value3Text.split('*');
      if (parts.length == 2) {
        double multiplier = double.tryParse(parts[1]) ?? 1.0;
        totalSum = (totalSum * multiplier).toInt();
      }
    }

    FirebaseFirestore.instance
        .collection('Cities') // Cities collection
        .doc(selectedCity) // Specific city document (e.g., 'Lahore')
        .collection(
            '${selectedCity}Plants') // Veggies collection under that city
        .doc(product.id) // Product document
        .update({
      'price': totalSum.toString(),
      'value1': value1Controller.text,
      'value2': value2Controller.text,
      'value3': value3Controller.text,
    }).then((_) {
      // Update value1 in veggies_values collection
      _updateValue('value1', value1Controller.text);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Product updated successfully'),
        duration: Duration(seconds: 2),
      ));
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to update product: $error'),
        duration: const Duration(seconds: 2),
      ));
    });
  }

  void _showEditDialog(BuildContext context, QueryDocumentSnapshot product) {
    TextEditingController nameController =
        TextEditingController(text: product['name']);
    TextEditingController priceController =
        TextEditingController(text: product['price']);
    TextEditingController urlController =
        TextEditingController(text: product['url']); // Add this line
    final selectedCity = ref.watch(cityProvider);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Product'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Product Price'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                // Add this TextField for URL editing
                controller: urlController,
                decoration: const InputDecoration(labelText: 'Image URL'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                String newName = nameController.text.trim();
                String newPrice = priceController.text.trim();
                String newUrl =
                    urlController.text.trim(); // Retrieve the URL text

                if (newName.isNotEmpty &&
                    newPrice.isNotEmpty &&
                    newUrl.isNotEmpty) {
                  FirebaseFirestore.instance
                      .collection('Cities') // Cities collection
                      .doc(
                          selectedCity) // Specific city document (e.g., 'Lahore')
                      .collection(
                          '${selectedCity}Plants') // Veggies collection under that city
                      .doc(product.id) // Product document
                      .update({
                    'name': newName,
                    'price': newPrice,
                    'url': newUrl,
                    // Update the URL in Firestore
                  }).then((_) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Product updated successfully'),
                      duration: Duration(seconds: 2),
                    ));
                  }).catchError((error) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Failed to update product: $error'),
                      duration: const Duration(seconds: 2),
                    ));
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Please fill in all fields'),
                    duration: Duration(seconds: 2),
                  ));
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, String productId) {
    final selectedCity = ref.watch(cityProvider);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Product'),
          content: const Text('Are you sure you want to delete this product?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('Cities') // Cities collection
                    .doc(
                        selectedCity) // Specific city document (e.g., 'Lahore')
                    .collection(
                        '${selectedCity}Plants') // Veggies collection under that city
                    .doc(productId) // Product document
                    .delete()
                    .then((_) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Product deleted successfully'),
                    duration: Duration(seconds: 2),
                  ));
                }).catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Failed to delete product: $error'),
                    duration: const Duration(seconds: 2),
                  ));
                });
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
