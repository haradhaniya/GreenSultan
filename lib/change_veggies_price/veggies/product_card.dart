import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_sultan/provider/city_provider.dart';

class ProductCard extends ConsumerStatefulWidget {
  final QueryDocumentSnapshot product;
  final bool isPinVerified;
  final int index;

  const ProductCard({
    super.key,
    required this.product,
    required this.isPinVerified,
    required this.index,
  });

  @override
  ProductCardState createState() => ProductCardState();
}

class ProductCardState extends ConsumerState<ProductCard> {
  late TextEditingController _value1Controller;
  late TextEditingController _value2Controller;
  late TextEditingController _value3Controller;
  String _currentPrice = "";
  String _value1 = "";
  String _value2 = "";
  String _value3 = "";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _value1Controller = TextEditingController();
    _value2Controller = TextEditingController();
    _value3Controller = TextEditingController();

    // Fetch the data after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchData().then((_) {
        // Update controllers with fetched values
        setState(() {
          _value1Controller.text = _value1;
          _value2Controller.text = _value2;
          _value3Controller.text = _value3;
        });
      });
    });
  }

  Future<void> fetchData() async {
    final selectedCity = ref.watch(cityProvider);
    if (selectedCity == null || selectedCity.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // First, get the current product price from the main collection
      final productDoc = await FirebaseFirestore.instance
          .collection('Cities')
          .doc(selectedCity)
          .collection('${selectedCity}Veggies')
          .doc(widget.product.id)
          .get();

      // Then, get the calculation values from the veggies_values collection
      final valuesDoc = await FirebaseFirestore.instance
          .collection('Cities')
          .doc(selectedCity)
          .collection('veggies_values')
          .doc(widget.product.id)
          .get();

      if (mounted) {
        setState(() {
          _isLoading = false;

          // Get price from the main collection
          if (productDoc.exists && productDoc.data() != null) {
            final data = productDoc.data()!;
            _currentPrice = data['price'] ?? '0';
          } else {
            _currentPrice = '0';
          }

          // Get values from the veggies_values collection
          if (valuesDoc.exists && valuesDoc.data() != null) {
            final data = valuesDoc.data()!;
            _value1 = data['value1'] ?? '';
            _value2 = data['value2'] ?? '';
            _value3 = data['value3'] ?? '';
          } else {
            _value1 = '';
            _value2 = '';
            _value3 = '';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar(context, 'Error fetching data: $e', isError: true);
      }
    }
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
    final productData = widget.product.data() as Map<String, dynamic>?;

    if (productData == null) {
      return Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Error: Product data is unavailable',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ),
      );
    }

    // Use the local state value for current price instead of directly from productData
    final displayPrice = _isLoading
        ? 'Loading...'
        : (_currentPrice.isEmpty ? '0' : _currentPrice);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.green.shade50,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image with container
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildProductImage(productData['url']),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Product Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Name
                        Text(
                          productData['name'] ?? 'Unknown Product',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Price with highlighted container
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'Rs$displayPrice',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Buttons
                        Row(
                          children: [
                            // Edit button is always visible
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _showEditDialog(context),
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Edit'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),

                            // Show Price button only when PIN verified
                            if (widget.isPinVerified) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      _showCalculatorDialog(context),
                                  icon: const Icon(Icons.calculate, size: 16),
                                  label: const Text('Price'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],

                            // Show Delete button instead when PIN is not verified
                            if (!widget.isPinVerified) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _showDeleteDialog(
                                      context, widget.product.id),
                                  icon: const Icon(Icons.delete, size: 16),
                                  label: const Text('Delete'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        child: const Icon(
          Icons.image_not_supported,
          size: 40,
          color: Colors.grey,
        ),
      );
    }

    return Image.network(
      imageUrl,
      height: double.infinity,
      width: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Error loading image: $error');
        return Container(
          color: Colors.grey.shade200,
          child: const Icon(
            Icons.broken_image,
            size: 40,
            color: Colors.grey,
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    (loadingProgress.expectedTotalBytes ?? 1)
                : null,
            strokeWidth: 2,
            color: Colors.green,
          ),
        );
      },
    );
  }

  // Method to refresh data from Firestore
  Future<void> refreshData() async {
    await fetchData();
    setState(() {
      // Update controllers with latest values
      _value1Controller.text = _value1;
      _value2Controller.text = _value2;
      _value3Controller.text = _value3;
    });
  }

  void _calculateAndUpload(
      BuildContext context,
      QueryDocumentSnapshot product,
      TextEditingController value1Controller,
      TextEditingController value2Controller,
      TextEditingController value3Controller) {
    // Check if PIN is verified first
    if (!widget.isPinVerified) {
      _showSnackBar(
          context, 'PIN verification required to modify product prices',
          isError: true);
      return;
    }

    // Validate inputs and get selected city
    final selectedCity = ref.watch(cityProvider);
    if (selectedCity == null || selectedCity.isEmpty) {
      _showSnackBar(context, 'Error: No city selected', isError: true);
      return;
    }

    try {
      // Parse input values
      int value1 = int.tryParse(value1Controller.text.trim()) ?? 0;
      int value2 = int.tryParse(value2Controller.text.trim()) ?? 0;
      String value3Text = value3Controller.text.trim();

      // If value1 is 0 or empty, result is 0
      if (value1 == 0) {
        _showSnackBar(
            context, 'Value 1 is 0 or empty, resulting in a total of 0');

        _updatePrice(context, product.id, '0', selectedCity).then((_) {
          setState(() {
            _currentPrice = '0';
          });

          // Also update the value fields in the veggies_values collection
          _updateValues(product.id, value1Controller.text,
                  value2Controller.text, value3Controller.text, selectedCity)
              .then((_) {
            refreshData(); // Refresh data after update
          });
        });
        return;
      }

      // Calculate total sum
      int totalSum = value1 + value2;

      // Apply operations from value3 if present
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

      final newPrice = totalSum.toString();

      // Update the price in the main collection
      _updatePrice(context, product.id, newPrice, selectedCity).then((_) {
        // Update the UI
        setState(() {
          _currentPrice = newPrice;
        });

        // Also update the values in the veggies_values collection
        _updateValues(product.id, value1Controller.text, value2Controller.text,
                value3Controller.text, selectedCity)
            .then((_) {
          refreshData(); // Refresh data after update

          _showSnackBar(context, 'Product updated successfully');
        });
      }).catchError((error) {
        _showSnackBar(context, 'Failed to update product: $error',
            isError: true);
      });
    } catch (e) {
      _showSnackBar(context, 'Error during calculation: $e', isError: true);
    }
  }

  // Helper method to update the price in the main collection
  Future<void> _updatePrice(BuildContext context, String productId,
      String price, String selectedCity) {
    return FirebaseFirestore.instance
        .collection('Cities')
        .doc(selectedCity)
        .collection('${selectedCity}Veggies')
        .doc(productId)
        .update({
      'price': price,
    });
  }

  // Helper method to update the values in the veggies_values collection
  Future<void> _updateValues(String productId, String value1, String value2,
      String value3, String selectedCity) {
    return FirebaseFirestore.instance
        .collection('Cities')
        .doc(selectedCity)
        .collection('veggies_values')
        .doc(productId)
        .set({
      'value1': value1,
      'value2': value2,
      'value3': value3,
    }, SetOptions(merge: true));
  }

  // Show the calculator dialog to update product price
  void _showCalculatorDialog(BuildContext context) {
    // Check if PIN is verified first
    if (!widget.isPinVerified) {
      _showSnackBar(
          context, 'PIN verification required to modify product prices',
          isError: true);
      return;
    }

    final selectedCity = ref.watch(cityProvider);
    if (selectedCity == null || selectedCity.isEmpty) {
      _showSnackBar(context, 'Error: No city selected', isError: true);
      return;
    }

    // Update controllers with current values first
    _value1Controller.text = _value1;
    _value2Controller.text = _value2;
    _value3Controller.text = _value3;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.calculate, color: Colors.green),
              const SizedBox(width: 8),
              const Text('Price Calculator'),
              const SizedBox(width: 8),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Current: ",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          "Rs$_currentPrice",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Text(
                  "Formula: Value1 + Value2, then apply operation in Value3",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                // Value 1 field
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green.shade200),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.green.shade50,
                  ),
                  child: TextField(
                    controller: _value1Controller,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'Value 1 (Main)',
                      labelStyle: TextStyle(color: Colors.green.shade700),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      prefixIcon:
                          Icon(Icons.onetwothree, color: Colors.green.shade700),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Value 2 field
                TextField(
                  controller: _value2Controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Value 2 (Addition)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.add),
                  ),
                ),
                const SizedBox(height: 16),
                // Value 3 field with help text
                TextField(
                  controller: _value3Controller,
                  decoration: const InputDecoration(
                    labelText: 'Value 3 (Operation)',
                    border: OutlineInputBorder(),
                    hintText: 'e.g. /2 or *1.5',
                    helperText: 'Use /X to divide or *X to multiply',
                    prefixIcon: Icon(Icons.functions),
                  ),
                ),
                const SizedBox(height: 8),
                // Example calculations
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Examples:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "• If Value1=100, Value2=20, Value3='/2', result will be 60",
                        style: TextStyle(
                            fontSize: 12, color: Colors.blue.shade800),
                      ),
                      Text(
                        "• If Value1=100, Value2=20, Value3='*1.5', result will be 180",
                        style: TextStyle(
                            fontSize: 12, color: Colors.blue.shade800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('CANCEL'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                _calculateAndUpload(
                  context,
                  widget.product,
                  _value1Controller,
                  _value2Controller,
                  _value3Controller,
                );
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.check),
              label: const Text('CALCULATE & UPDATE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(BuildContext context) {
    // Add null safety to product data extraction
    final productData = widget.product.data() as Map<String, dynamic>?;
    if (productData == null) {
      _showSnackBar(context, 'Error: No product data available', isError: true);
      return;
    }

    final selectedCity = ref.watch(cityProvider);
    if (selectedCity == null || selectedCity.isEmpty) {
      _showSnackBar(context, 'Error: No city selected', isError: true);
      return;
    }

    // Initialize controllers with existing values
    final nameController =
        TextEditingController(text: productData['name'] ?? '');
    final priceController = TextEditingController(text: _currentPrice);
    final urlController = TextEditingController(text: productData['url'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.edit, color: Colors.green),
              const SizedBox(width: 8),
              const Flexible(
                child: Text(
                  'Edit Product',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Product image preview
                if (urlController.text.isNotEmpty)
                  Container(
                    height: 100,
                    width: 100,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildProductImage(urlController.text),
                    ),
                  ),

                // Name field
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Product Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.inventory),
                  ),
                ),
                const SizedBox(height: 16),

                // Price field
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Price (Rs)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.money),
                  ),
                ),
                const SizedBox(height: 16),

                // URL field
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    border: OutlineInputBorder(),
                    hintText: 'https://example.com/image.jpg',
                    prefixIcon: Icon(Icons.image),
                    helperText: 'Enter a valid image URL',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('CANCEL'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                final newName = nameController.text.trim();
                final newPrice = priceController.text.trim();
                final newUrl = urlController.text.trim();

                // Validate that all fields are filled
                if (newName.isEmpty || newPrice.isEmpty || newUrl.isEmpty) {
                  _showSnackBar(context, 'Please fill in all fields',
                      isError: true);
                  return;
                }

                // Update the product in Firestore
                try {
                  FirebaseFirestore.instance
                      .collection('Cities')
                      .doc(selectedCity)
                      .collection('${selectedCity}Veggies')
                      .doc(widget.product.id)
                      .update({
                    'name': newName,
                    'price': newPrice,
                    'url': newUrl,
                  }).then((_) {
                    // Update the UI with the new values
                    setState(() {
                      _currentPrice = newPrice;
                    });

                    // Show success message
                    _showSnackBar(context, 'Product updated successfully');

                    // Refresh data from Firestore
                    refreshData();
                  }).catchError((error) {
                    _showSnackBar(context, 'Failed to update product: $error',
                        isError: true);
                  });
                } catch (e) {
                  _showSnackBar(context, 'Error: $e', isError: true);
                }

                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.save),
              label: const Text('SAVE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  // Helper method to show snackbar messages with consistent styling
  void _showSnackBar(BuildContext context, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green.shade700,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  // Method to update the delete dialog UI
  void _showDeleteDialog(BuildContext context, String productId) {
    final selectedCity = ref.watch(cityProvider);
    if (selectedCity == null || selectedCity.isEmpty) {
      _showSnackBar(context, 'Error: No city selected', isError: true);
      return;
    }

    final productData = widget.product.data() as Map<String, dynamic>?;
    if (productData == null) {
      _showSnackBar(context, 'Error: No product data available', isError: true);
      return;
    }

    final productName = productData['name'] ?? 'this product';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.delete, color: Colors.red),
              const SizedBox(width: 8),
              const Flexible(
                child: Text(
                  'Delete Product',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    const TextSpan(text: 'Are you sure you want to delete "'),
                    TextSpan(
                      text: productName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(text: '"?'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.red),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'This action cannot be undone',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('CANCEL'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(color: Colors.red),
                  ),
                );

                FirebaseFirestore.instance
                    .collection('Cities')
                    .doc(selectedCity)
                    .collection('${selectedCity}Veggies')
                    .doc(productId)
                    .delete()
                    .then((_) {
                  // Close loading dialog
                  Navigator.of(context).pop();
                  Navigator.of(context)
                      .pop(); // Close delete confirmation dialog
                  _showSnackBar(context, 'Product deleted successfully');
                }).catchError((error) {
                  // Close loading dialog
                  Navigator.of(context).pop();
                  Navigator.of(context)
                      .pop(); // Close delete confirmation dialog
                  _showSnackBar(
                    context,
                    'Failed to delete product: $error',
                    isError: true,
                  );
                });
              },
              icon: const Icon(Icons.delete_forever),
              label: const Text('DELETE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }
}
