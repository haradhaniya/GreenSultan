import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_sultan/provider/city_provider.dart';
import 'package:green_sultan/features/home/views/product_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class ProductForm extends ConsumerStatefulWidget {
  final String categoryId;
  final String subCategoryId;
  final String? productId;
  final String selectedCity;
  final String? subCategoryName;

  const ProductForm({
    super.key,
    required this.categoryId,
    required this.subCategoryId,
    required this.selectedCity,
    this.productId,
    this.subCategoryName,
  });

  @override
  ConsumerState<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends ConsumerState<ProductForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController stockController = TextEditingController();
  
  // Multiple image support
  final List<TextEditingController> imageUrlControllers = [
    TextEditingController(), // Main image (first one)
  ];
  int numImages = 1;

  // Size & Price options
  List<TextEditingController> optionLabelControllers = [TextEditingController()];
  List<TextEditingController> optionPriceControllers = [TextEditingController()];
  int numOptions = 1;
  final List<Map<String, dynamic>> sizesAndPrices = [];

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    stockController.dispose();
    for (var controller in imageUrlControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Product"),
        centerTitle: true,
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Selected City: ${widget.selectedCity}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              
              if (widget.subCategoryName != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'Subcategory: ${widget.subCategoryName}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),

              // Main image preview (tappable)
              _buildMainImagePreview(),
              const SizedBox(height: 16),
              
              // Dynamic image URL fields
              _buildImageUrlFields(),
              const SizedBox(height: 16),

              // Product details
              _buildTextField(
                  nameController, "Product Name", "Enter product name"),
              _buildTextField(descriptionController, "Product Description",
                  "Enter description"),

              // Size & Price options
              _buildSizeAndPriceFields(),
              const SizedBox(height: 10),

              // Stock
              _buildTextField(stockController, "Stock", "Enter stock quantity",
                  isNumber: true),
              const SizedBox(height: 20),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _saveProductToFirestore(widget.selectedCity),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Save Product',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainImagePreview() {
    if (imageUrlControllers[0].text.isEmpty) {
      return Container(
        height: 200,
        color: Colors.grey[200],
        alignment: Alignment.center,
        child: const Text("No image selected"),
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductGalleryScreen(
              imageUrls: imageUrlControllers
                  .map((c) => c.text)
                  .where((url) => url.isNotEmpty)
                  .toList(),
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrlControllers[0].text,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image, size: 50),
          ),
        ),
      ),
    );
  }

  Widget _buildImageUrlFields() {
    return Column(
      children: [
        const Text(
          "Product Images",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Column(
          children: List.generate(numImages, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: imageUrlControllers[index],
                      decoration: InputDecoration(
                        labelText: index == 0 ? "Main Image URL" : "Extra Image URL",
                        hintText: "Enter image URL",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (index == 0 && (value == null || value.isEmpty)) {
                          return 'Main image is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  if (index != 0)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          imageUrlControllers.removeAt(index);
                          numImages--;
                        });
                      },
                    ),
                ],
              ),
            );
          }),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              numImages++;
              imageUrlControllers.add(TextEditingController());
            });
          },
          child: const Text("Add Another Image"),
        ),
      ],
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, String hint,
      {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '$label is required';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSizeAndPriceFields() {
    return Column(
      children: [
        const Text("Size & Price",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Column(
          children: List.generate(numOptions, (index) {
            return Row(
              children: [
                Expanded(
                    child: _buildTextField(
                        optionLabelControllers[index], "Size", "Enter size")),
                const SizedBox(width: 10),
                Expanded(
                    child: _buildTextField(
                        optionPriceControllers[index], "Price", "Enter price",
                        isNumber: true)),
              ],
            );
          }),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  numOptions++;
                  optionLabelControllers.add(TextEditingController());
                  optionPriceControllers.add(TextEditingController());
                });
              },
              child: const Icon(Icons.add),
            ),
            ElevatedButton(
              onPressed: () {
                if (numOptions > 1) {
                  setState(() {
                    numOptions--;
                    optionLabelControllers.removeLast();
                    optionPriceControllers.removeLast();
                  });
                }
              },
              child: const Icon(Icons.remove),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _saveProductToFirestore(String cityId) async {
    if (!_formKey.currentState!.validate()) return;

    final List<String> imageUrls = imageUrlControllers
        .map((controller) => controller.text)
        .where((url) => url.isNotEmpty)
        .toList();

    if (imageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one image is required')),
      );
      return;
    }

    if (sizesAndPrices.isEmpty) {
      sizesAndPrices.clear();
      for (int i = 0; i < numOptions; i++) {
        final size = optionLabelControllers[i].text;
        final price = optionPriceControllers[i].text;
        if (size.isNotEmpty && price.isNotEmpty) {
          sizesAndPrices.add({
            'size': size,
            'price': double.parse(price),
          });
        }
      }
      
      if (sizesAndPrices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('At least one size and price is required')),
        );
        return;
      }
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      // First, ensure the subcategory exists
      final subcategoryRef = FirebaseFirestore.instance
          .collection('Cities')
          .doc(cityId)
          .collection('categories')
          .doc(widget.categoryId)
          .collection('subcategory')
          .doc(widget.subCategoryId);
      
      final subcategoryDoc = await subcategoryRef.get();
      
      // If subcategory doesn't exist, create it with default values
      if (!subcategoryDoc.exists) {
        await subcategoryRef.set({
          'name': widget.subCategoryId,
          'imageUrl': imageUrls[0], // Use the first product image as default subcategory image
        });
      }
      
      // Add the product to the products collection
      await subcategoryRef.collection('products').add({
        'name': nameController.text,
        'description': descriptionController.text,
        'images': imageUrls,
        'sizesAndPrices': sizesAndPrices,
        'stock': int.parse(stockController.text),
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Close loading dialog
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product saved successfully')),
      );
      Navigator.pop(context); // Return to previous screen
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save product: $e')),
      );
    }
  }
}

class ProductGalleryScreen extends StatelessWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const ProductGalleryScreen({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      body: PageView.builder(
        itemCount: imageUrls.length,
        controller: PageController(initialPage: initialIndex),
        itemBuilder: (context, index) {
          return InteractiveViewer(
            panEnabled: true,
            scaleEnabled: true,
            child: Center(
              child: Image.network(
                imageUrls[index],
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image,
                  color: Colors.white,
                  size: 100,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}