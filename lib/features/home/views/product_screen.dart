import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:green_sultan/models/productModel.dart';
import 'package:green_sultan/provider/product_provider.dart';
import 'package:green_sultan/provider/selected_city_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class ProductScreen extends ConsumerStatefulWidget {
  final String categoryId;
  final String categoryName;
  final String subcategoryId;
  final String subcategoryName;

  const ProductScreen({
    Key? key,
    required this.categoryId,
    required this.categoryName,
    required this.subcategoryId,
    required this.subcategoryName,
  }) : super(key: key);

  @override
  ConsumerState<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends ConsumerState<ProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  List<File> _imageFiles = [];
  List<String> _imageUrls = [];
  bool _isUploading = false;
  bool _isProcessing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    
    if (pickedFiles.isNotEmpty) {
      setState(() {
        for (var pickedFile in pickedFiles) {
          _imageFiles.add(File(pickedFile.path));
        }
      });
    }
  }

  Future<List<String>> _uploadImages() async {
    if (_imageFiles.isEmpty) return [];
    
    setState(() {
      _isUploading = true;
    });
    
    List<String> uploadedUrls = [];
    
    try {
      final selectedCity = ref.read(selectedCityProvider);
      if (selectedCity == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No city selected')),
        );
        return [];
      }
      
      for (var imageFile in _imageFiles) {
        final fileName = path.basename(imageFile.path);
        final destination = 'products/$selectedCity/${widget.categoryId}/${widget.subcategoryId}/${DateTime.now().millisecondsSinceEpoch}_$fileName';
        final ref = FirebaseStorage.instance.ref().child(destination);
        
        final task = await ref.putFile(imageFile);
        final downloadUrl = await task.ref.getDownloadURL();
        uploadedUrls.add(downloadUrl);
      }
      
      setState(() {
        _isUploading = false;
      });
      
      return uploadedUrls;
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload images: $e')),
      );
      return [];
    }
  }

  Future<void> _createProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    final selectedCity = ref.read(selectedCityProvider);
    if (selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a city first')),
      );
      return;
    }
    
    if (_imageFiles.isEmpty && _imageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one image')),
      );
      return;
    }
    
    setState(() {
      _isProcessing = true;
    });

    try {
      // Upload new images
      List<String> newImageUrls = [];
      if (_imageFiles.isNotEmpty) {
        newImageUrls = await _uploadImages();
        if (newImageUrls.isEmpty && _imageUrls.isEmpty) {
          setState(() {
            _isProcessing = false;
          });
          return;
        }
      }
      
      // Combine existing and new image URLs
      final allImageUrls = [..._imageUrls, ...newImageUrls];

      // Create product document
      final price = double.tryParse(_priceController.text) ?? 0.0;
      final stock = int.tryParse(_stockController.text) ?? 0;
      
      await FirebaseFirestore.instance
          .collection('Cities')
          .doc(selectedCity)
          .collection('categories')
          .doc(widget.categoryId)
          .collection('subcategory')
          .doc(widget.subcategoryId)
          .collection('products')
          .add({
            'name': _nameController.text,
            'description': _descriptionController.text,
            'price': price,
            'stock': stock,
            'images': allImageUrls,
            'categoryId': widget.categoryId,
            'subcategoryId': widget.subcategoryId,
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
          });
      
      setState(() {
        _nameController.clear();
        _descriptionController.clear();
        _priceController.clear();
        _stockController.clear();
        _imageFiles = [];
        _imageUrls = [];
        _isProcessing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product created successfully')),
      );
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating product: $e')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      if (index < _imageUrls.length) {
        _imageUrls.removeAt(index);
      } else {
        _imageFiles.removeAt(index - _imageUrls.length);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedCity = ref.watch(selectedCityProvider);
    
    if (selectedCity == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Products')),
        body: const Center(child: Text('Please select a city first')),
      );
    }

    final productsAsync = ref.watch(
      productsProvider((selectedCity, widget.categoryId, widget.subcategoryId))
    );
    
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.subcategoryName} - Products'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Create product form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(10.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Selected City: $selectedCity', 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Selected Category: ${widget.categoryName}', 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Selected Subcategory: ${widget.subcategoryName}', 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    
                    // Product name field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a product name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    
                    // Product description field
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a product description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    
                    // Price field
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price (SAR)',
                        border: OutlineInputBorder(),
                      ),
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
                    const SizedBox(height: 8),
                    
                    // Stock field
                    TextFormField(
                      controller: _stockController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity in Stock',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter quantity';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    
                    // Image preview grid
                    if (_imageUrls.isNotEmpty || _imageFiles.isNotEmpty) ...[
                      const Text('Selected Images:', 
                        style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                      
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _imageUrls.length + _imageFiles.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: index < _imageUrls.length
                                    ? Image.network(
                                        _imageUrls[index],
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                        errorBuilder: (context, error, stackTrace) => const Icon(
                                          Icons.image_not_supported,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                      )
                                    : Image.file(
                                        _imageFiles[index - _imageUrls.length],
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: InkWell(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    // Image picker button
                    ElevatedButton.icon(
                      onPressed: _isUploading ? null : _pickImages,
                      icon: const Icon(Icons.image),
                      label: const Text('Select Images'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Create button
                    ElevatedButton(
                      onPressed: _isProcessing || _isUploading ? null : _createProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: _isProcessing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Create Product', 
                              style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Divider
          const Divider(thickness: 1),
          
          // Product list
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
              data: (products) {
                if (products.isEmpty) {
                  return const Center(
                    child: Text('No products found. Create one above.'),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min, // Prevent overflow
                          children: [
                            if (product.images.isNotEmpty)
                              SizedBox(
                                height: 200,
                                child: PageView.builder(
                                  itemCount: product.images.length,
                                  itemBuilder: (context, imgIndex) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        product.images[imgIndex],
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Center(
                                          child: Icon(
                                            Icons.image_not_supported,
                                            size: 50,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              )
                            else
                              Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),

                            const SizedBox(height: 5),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        product.description,
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 14,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${product.price.toStringAsFixed(2)} SAR',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.green,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'In Stock: ${product.stock}',
                                        style: TextStyle(
                                          color: product.stock > 0 ? Colors.green : Colors.red,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
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
          ),
        ],
      ),
    );
  }
} 