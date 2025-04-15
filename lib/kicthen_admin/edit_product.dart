import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:green_sultan/models/productModel.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;
  final String cityId;
  final String categoryId;
  final String subcategoryId;

  const EditProductScreen({
    super.key,
    required this.product,
    required this.categoryId,
    required this.subcategoryId,
    required this.cityId,
  });

  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _stockController;
  late List<TextEditingController> _imageControllers;
  late List<SizeAndPriceController> _sizeAndPriceControllers;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _descriptionController =
        TextEditingController(text: widget.product.description);
    _stockController =
        TextEditingController(text: widget.product.stock.toString());

    // Initialize image controllers
    _imageControllers = widget.product.images
        .map((image) => TextEditingController(text: image))
        .toList();
    if (_imageControllers.isEmpty) {
      _imageControllers.add(TextEditingController());
    }

    // Initialize controllers for sizes and prices
    _sizeAndPriceControllers = widget.product.sizesAndPrices
        .map((sizePrice) => SizeAndPriceController(
              size: TextEditingController(text: sizePrice.size),
              price: TextEditingController(text: sizePrice.price.toString()),
            ))
        .toList();
    
    if (_sizeAndPriceControllers.isEmpty) {
      _sizeAndPriceControllers.add(
        SizeAndPriceController(
          size: TextEditingController(),
          price: TextEditingController(text: widget.product.price.toString()),
        ),
      );
    }
  }

  Future<void> _updateProduct() async {
    if (_formKey.currentState!.validate()) {
      if (widget.product.id.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Product ID is empty')),
        );
        return;
      }

      // Get all non-empty image URLs
      final imageUrls = _imageControllers
          .map((controller) => controller.text)
          .where((url) => url.isNotEmpty)
          .toList();

      if (imageUrls.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('At least one image is required')),
        );
        return;
      }

      // Convert controllers back to SizeAndPrice objects
      final updatedSizesAndPrices = _sizeAndPriceControllers
          .map((controller) => SizeAndPrice(
                size: controller.size.text,
                price: double.parse(controller.price.text),
              ))
          .toList();

      final updatedProduct = Product(
        id: widget.product.id,
        name: _nameController.text,
        description: _descriptionController.text,
        price: updatedSizesAndPrices.isNotEmpty 
            ? updatedSizesAndPrices.first.price 
            : double.parse(_sizeAndPriceControllers.first.price.text),
        stock: int.parse(_stockController.text),
        images: imageUrls,
        sizesAndPrices: updatedSizesAndPrices,
        categoryId: widget.product.categoryId,
        subcategoryId: widget.product.subcategoryId,
        isActive: widget.product.isActive,
        createdAt: widget.product.createdAt,
      );

      try {
        await FirebaseFirestore.instance
            .collection('Cities')
            .doc(widget.cityId)
            .collection('categories')
            .doc(widget.categoryId)
            .collection('subcategory')
            .doc(widget.subcategoryId)
            .collection('products')
            .doc(updatedProduct.id)
            .update(updatedProduct.toMap());

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully')),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating product: $e')),
        );
      }
    }
  }

  void _addImageField() {
    setState(() {
      _imageControllers.add(TextEditingController());
    });
  }

  void _removeImageField(int index) {
    if (_imageControllers.length > 1) {
      setState(() {
        _imageControllers.removeAt(index);
      });
    }
  }

  void _addSizeAndPrice() {
    setState(() {
      _sizeAndPriceControllers.add(
        SizeAndPriceController(
          size: TextEditingController(),
          price: TextEditingController(),
        ),
      );
    });
  }

  void _removeSizeAndPrice(int index) {
    setState(() {
      _sizeAndPriceControllers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the stock';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Product Images',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Column(
                children: List.generate(_imageControllers.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _imageControllers[index],
                            decoration: InputDecoration(
                              labelText: index == 0
                                  ? 'Main Image URL'
                                  : 'Additional Image URL',
                              hintText: 'Enter image URL',
                            ),
                            validator: (value) {
                              if (index == 0 &&
                                  (value == null || value.isEmpty)) {
                                return 'Main image is required';
                              }
                              return null;
                            },
                          ),
                        ),
                        if (index != 0)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeImageField(index),
                          ),
                      ],
                    ),
                  );
                }),
              ),
              ElevatedButton(
                onPressed: _addImageField,
                child: const Text('Add Another Image'),
              ),
              const SizedBox(height: 20),
              const Text(
                'Sizes and Prices',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ..._sizeAndPriceControllers.asMap().entries.map((entry) {
                final index = entry.key;
                final controller = entry.value;
                return Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller.size,
                        decoration: const InputDecoration(labelText: 'Size'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a size';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: controller.price,
                        decoration: const InputDecoration(labelText: 'Price'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a price';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeSizeAndPrice(index),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _addSizeAndPrice,
                child: const Text('Add Size and Price'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Update Product',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SizeAndPriceController {
  final TextEditingController size;
  final TextEditingController price;

  SizeAndPriceController({
    required this.size,
    required this.price,
  });
}